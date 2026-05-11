/*----------------------------------------------------------------------------
    Author:               liu sheng
  Creation Date:         2025-07-03     
-----------------------------------------------------------------------------*/

/*===========================================================================*
Program Name        :  * ESD_outliers.sas*
Path                :  *程序保存的路径*
Program Language    :  SAS V9.4
______________________________________________________________________________

Purpose             : * 离群值检测_使用“广义极端学生化偏差（ESD）”法检测 *

Macro Calls         : * *


Input               :  
Output              : 

Program Flow        : *编程步骤*

     *1.  创建程序 *

______________________________________________________________________________

Version History     : *版本信息*

Version     Date           Programmer       Description
-------     ----------     ----------       -----------
1.0        2025-07-03      liusheng         创建程序

==========================================================================*/



/* ----------------------------------------ESD法检测离群值------------------------------------- */

%macro ESD_outliers( indata = , outdata = ,var = , max_n =%str() , max_rate=0.05, alpha=0.05 ,debug=0);

/* 
    indata      : 输入数据集
    outdata     : 输出数据集
    var         : 检测离群值的定量结果变量(对于IVD两组，EP9-A3考虑了d，即差值或差值百分比)
    max_n       : 最大离群值数，默认为空，即按照比例（max_rate）自动读取，不应超过样本的5%，向下取整（如44例样本，取max_n=2）
                    （EP9-A3：Set the upper bound on number of potential outliers (h) at this 5% level）
    max_rate    : 最大离群值不应超过样本总数的比例，默认为5%（EP9-A3描述）
    alpha       : 显著性水平，默认为0.05
    debug       : 是否删掉过程数据，以便测试宏程序时查看中间数据集，默认debug=0,即删除。
    
*/




/* ------读取数据---- */
data indata_temp ;
    set &indata ;
    _temp_seq = monotonic() ;
run;

/* 当没有指定最大离群值数max_n时，自动读取 */
%if %length(&max_n)=0 %then %do;
data _null_;
    set indata_temp end=last;
    if last then do;
        /* 向下取整 floor */
        call symput("max_n", floor(_n_*&max_rate) );
    end;
run;
%end;

%put  &=max_n;

/* 循环迭代至 最大离群值数（max_n） */
%do i=1 %to &max_n;
    /* 每一次迭代，计算 均值，标准差 */
    proc means data = indata_temp noprint;
        var &var ;
        output out = _temp_meanc
                    mean=mean std=std n=n ;
    quit;
    /* 加载means结果，与原始数据 合并计算 “极端偏差值r” */
    data _temp_diff_r&i;
        if _n_ = 1 then set _temp_meanc;
        set indata_temp ;
        r = abs(&var - mean) / std;
        /* 读取初始总数 */
        if &i=1 then do;
            call symputx("ESD_total_n",n);
        end;
    run;
    /* 极端偏差值 : 找出当前最大R值的记录，逐一迭代 */
    proc sql undo_policy = none ;
        create table _temp_diff_r&i as
            select 
                *,
                &i as iteration label="迭代次数序号",
                (case when max(r)=r then "Y" end) as max_r_yn label="是否本次迭代最大的 极端偏差值"
        from _temp_diff_r&i ;
    quit;
                
    /* 从临时数据中剔除该记录(最大极端偏差r) */
    proc sql undo_policy = none ;
        create table indata_temp as select * from indata_temp
        where _temp_seq not in (select _temp_seq from _temp_diff_r&i where max_r_yn="Y"   );
    quit;
    /* 合并所有步骤的异常值 */
    %if &i=1 %then %do;
        data all_outliers;
            set  _temp_diff_r&i(where=( max_r_yn="Y" ))
        ;run;
    %end;
    %else %do;
        data all_outliers;
            set  all_outliers _temp_diff_r&i(where=( max_r_yn="Y" ))
        ;run;
    %end;
    
    /* 删除过程数据 */
    %if &debug=0 %then %do;
        proc delete data = _temp_meanc _temp_diff_r&i ;
        quit;
    %end;
%end;


/* 计算每步临界值 λi 并比较，输出最终数据集 */
data &outdata;
    set all_outliers;

    total_n = &ESD_total_n ;

    /* 文献是 lambda_i+1,从0开始 */
    L = iteration - 1;
    /* 当前剩余样本数 n - l */
    n_i = total_n - L  ;
    alpha_i = &alpha / (2 * n_i);
    /* t临界值，自由度为 n - l - 2 */
    t_value = tinv(1 - alpha_i, n_i - 2);
    /* 公式 */
    lambda = ((n_i - 1) * t_value) / sqrt(n_i * (n_i - 2 + t_value**2));
    /* 极端异常值 大于 界值，则为离群值 */
    if r > lambda then outlier_yn = "Y";
    else outlier_yn = "N";
    label outlier_yn = "是否为离群值";
run;

/* 删除过程数据 */
%if &debug=0 %then %do;
proc delete data = indata_temp  all_outliers;
quit;
%end;

%mend;






/* 测试：生成示例数据，正态分布数据，插入2个异常值 */
/*data sample_data;*/
/*    do id = 1 to 30;*/
/*        if id in (5, 25) then value = 100 + rannor(123); */
/*        else value = 50 + rannor(123);  */
/*        output;*/
/*    end;*/
/*run;*/
/**/
/**/
/*%ESD_outliers( indata = sample_data , outdata = test1 ,var =value , max_n =5 , alpha=0.05 ,debug=1);*/
/**/


