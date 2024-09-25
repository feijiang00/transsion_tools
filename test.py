import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle

# 设置图像大小和分辨率
plt.figure(figsize=(10, 7), dpi=100)

# 绘制大圆环
circle = Circle((0.5, 0.5), 0.4, color='blue', fill=False, linewidth=4)
plt.gca().add_patch(circle)

# 绘制SIT的方块图形
rectangle = Rectangle((0.4, 0.4), 0.2, 0.2, color='blue', fill=False, linewidth=2)
plt.gca().add_patch(rectangle)

# 添加文字
plt.text(0.5, 0.5, 'SIT', fontsize=20, ha='center', va='center', color='blue')
plt.text(0.5, 0.2, 'SHENYANG INSTITUTE OF TECHNOLOGY', fontsize=12, ha='center', va='center', color='blue')
plt.text(0.5, 0.9, '沈阳工学院', fontsize=20, ha='center', va='center', color='blue', fontproperties='SimHei')
plt.text(0.5, 0.8, '1999', fontsize=15, ha='center', va='center', color='blue')

# 移除坐标轴
plt.axis('off')

# 显示图像
plt.show()
