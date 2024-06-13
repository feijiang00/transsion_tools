import pandas as pd

# 读取两个 Excel 文件，设置列名为 None
df1 = pd.read_excel('f1.xlsx', header=None)
df2 = pd.read_excel('f2.xlsx', header=None)

# 合并两个 DataFrame，根据左侧值进行匹配
merged_df = pd.merge(df1, df2, on=0)

# 将结果保存到新的 Excel 文件
merged_df.to_excel('merged_values.xlsx', index=False)