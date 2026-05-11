# MACRO-for-ESD_outliers-in-SAS
  `离群值检测_基于“广义极端学生化偏差（ESD）”法。`  

# 必填参数目录content
- [indata](#indata)  
- [outdata](#outdata)  
- [var](#var)  

# 可选参数目录content
- [max_n](#max_n)  
- [max_rate](#max_rate)  
- [alpha](#alpha)  
- [debug](#debug)  

# 宏程序使用语法
```sas  
%ESD_outliers( indata = test1, outdata = out_test1 , var = age );  
%ESD_outliers( indata = test1, outdata = out_test1 , var = age  , max_rate=0.05, alpha=0.05 ,debug=0);  
```  

# 参数使用语法
## indata
  输入用于分析的数据集名称  
  分析数据集要求：至少有一列`定量数据变量`，目前程序不适用于`文本分析变量`的分析数据集。  
  
## outdata
  输出用于呈现分析结果的数据集名称。 

## var
  分析的定量数据变量名称，如`年龄（age）`。 

## max_n
  最大的离群值数，默认为空，即按照比例`max_rate`自动读取，`max_rate`不应超过样本的5%，向下取整（如44例样本，取max_n=2）

## max_rate
  `max_rate`不应超过样本的5%
  （来源：EP9-A3：Set the upper bound on number of potential outliers (h) at this 5% level）

## alpha
  显著性水平，默认为`alpha=0.05`，用于计算ESD法中临界值λ公式中的T分布统计值。

## debug
  是否删掉过程数据，以便测试宏程序时查看中间数据集，
  默认`debug=0`,即删除。
