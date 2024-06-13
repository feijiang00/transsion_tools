data = """
	Line 55:            TOTAL PSS:   441154            TOTAL RSS:   350932       TOTAL SWAP PSS:   169009
	Line 139:            TOTAL PSS:   130212            TOTAL RSS:   175816       TOTAL SWAP PSS:    23990
	Line 207:            TOTAL PSS:   119932            TOTAL RSS:   171320       TOTAL SWAP PSS:     8745
	Line 283:            TOTAL PSS:   353327            TOTAL RSS:   417076       TOTAL SWAP PSS:    39403
	Line 375:            TOTAL PSS:   530732            TOTAL RSS:   352120       TOTAL SWAP PSS:   265232
	Line 474:            TOTAL PSS:    19258            TOTAL RSS:    51776       TOTAL SWAP PSS:    17603
	Line 550:            TOTAL PSS:   578325            TOTAL RSS:   313544       TOTAL SWAP PSS:   345824
	Line 630:            TOTAL PSS:    54310            TOTAL RSS:    57272       TOTAL SWAP PSS:    50914
	Line 742:            TOTAL PSS:   235103            TOTAL RSS:   110212       TOTAL SWAP PSS:   195765
	Line 829:            TOTAL PSS:    29888            TOTAL RSS:    54584       TOTAL SWAP PSS:    24690
	Line 893:            TOTAL PSS:   127959            TOTAL RSS:    79868       TOTAL SWAP PSS:   111488
	Line 988:            TOTAL PSS:    52934            TOTAL RSS:    47976       TOTAL SWAP PSS:    51727
	Line 1054:            TOTAL PSS:    55845            TOTAL RSS:   109828       TOTAL SWAP PSS:    24950
	Line 1116:            TOTAL PSS:   137880            TOTAL RSS:   113352       TOTAL SWAP PSS:    94059
	Line 1218:            TOTAL PSS:   207137            TOTAL RSS:   159896       TOTAL SWAP PSS:   124732
	Line 1331:            TOTAL PSS:    31579            TOTAL RSS:    61908       TOTAL SWAP PSS:    16519
	Line 1392:            TOTAL PSS:    21189            TOTAL RSS:    64744       TOTAL SWAP PSS:     8279
	Line 1467:            TOTAL PSS:   145601            TOTAL RSS:   212236       TOTAL SWAP PSS:    10453
	Line 1553:            TOTAL PSS:    49658            TOTAL RSS:    56136       TOTAL SWAP PSS:    46779
	Line 1625:            TOTAL PSS:    19204            TOTAL RSS:    51248       TOTAL SWAP PSS:    17810
	Line 1689:            TOTAL PSS:     6056            TOTAL RSS:    55368       TOTAL SWAP PSS:     4150
	Line 1766:            TOTAL PSS:    63754            TOTAL RSS:    81988       TOTAL SWAP PSS:    49136
	Line 1841:            TOTAL PSS:     9574            TOTAL RSS:    50852       TOTAL SWAP PSS:     8826
	Line 1914:            TOTAL PSS:    28890            TOTAL RSS:    55084       TOTAL SWAP PSS:    26591
	Line 2013:            TOTAL PSS:     4726            TOTAL RSS:    43940       TOTAL SWAP PSS:     4094
	Line 2074:            TOTAL PSS:    34582            TOTAL RSS:    52712       TOTAL SWAP PSS:    31865
	Line 2141:            TOTAL PSS:     9653            TOTAL RSS:    43196       TOTAL SWAP PSS:     9012
	Line 2204:            TOTAL PSS:    19864            TOTAL RSS:    62844       TOTAL SWAP PSS:    10577
	Line 2274:            TOTAL PSS:    14851            TOTAL RSS:    55544       TOTAL SWAP PSS:    10169
	Line 2345:            TOTAL PSS:    56532            TOTAL RSS:    81028       TOTAL SWAP PSS:    32617
	Line 2406:            TOTAL PSS:    10981            TOTAL RSS:    54892       TOTAL SWAP PSS:     7870
	Line 2477:            TOTAL PSS:     7720            TOTAL RSS:    59732       TOTAL SWAP PSS:     5401
	Line 2545:            TOTAL PSS:    11473            TOTAL RSS:    62996       TOTAL SWAP PSS:     9297
	Line 2618:            TOTAL PSS:    54358            TOTAL RSS:    67840       TOTAL SWAP PSS:    48159
	Line 2697:            TOTAL PSS:    41792            TOTAL RSS:    68296       TOTAL SWAP PSS:    35919
	Line 2770:            TOTAL PSS:    30788            TOTAL RSS:    59768       TOTAL SWAP PSS:    24375
	Line 2842:            TOTAL PSS:    30128            TOTAL RSS:    51500       TOTAL SWAP PSS:    27128
	Line 2912:            TOTAL PSS:    24316            TOTAL RSS:    53508       TOTAL SWAP PSS:    22538
	Line 2984:            TOTAL PSS:    21508            TOTAL RSS:    53096       TOTAL SWAP PSS:    19636
	Line 3069:            TOTAL PSS:     4285            TOTAL RSS:    48980       TOTAL SWAP PSS:     3725
	Line 3129:            TOTAL PSS:    16287            TOTAL RSS:    50276       TOTAL SWAP PSS:    15230
	Line 3198:            TOTAL PSS:    44740            TOTAL RSS:    56444       TOTAL SWAP PSS:    36610
	Line 3284:            TOTAL PSS:    66882            TOTAL RSS:    48472       TOTAL SWAP PSS:    66051
	Line 3352:            TOTAL PSS:    42946            TOTAL RSS:    54808       TOTAL SWAP PSS:    35502
	Line 3412:            TOTAL PSS:     5757            TOTAL RSS:    47936       TOTAL SWAP PSS:     4816
"""

# 初始化总和变量
total_pss = 0
total_rss = 0
total_swap_pss = 0

# 处理每一行
# 处理每一行
for line in data.strip().split("\n"):
    parts = line.split()
    # 找到 TOTAL PSS, TOTAL RSS, TOTAL SWAP PSS 的值，并累加
    total_pss += int(parts[4])  # TOTAL PSS 的值现在在第5个位置
    total_rss += int(parts[7])  # TOTAL RSS 的值现在在第8个位置
    total_swap_pss += int(parts[10])  # TOTAL SWAP PSS 的值现在在第11个位置

# 打印结果
print("TOTAL PSS SUM:", total_pss)
print("TOTAL RSS SUM:", total_rss)
print("TOTAL SWAP PSS SUM:", total_swap_pss)