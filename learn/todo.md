# TODO

U上移植解决runable导致的滑动卡顿问题 
https://gerrit.transsion.com/c/TRAN_CODE/device/tran/product_parts/+/781215

#SPD: add for boost instagram draw threads priority by wei.kang 20230627 start
ifeq ($(strip $(TSSI_TRAN_FLING_RENDER_PRIORITY_BOOST_SUPPORT)), yes)
    PRODUCT_PRODUCT_PROPERTIES += ro.transsion.fling_render_boost_support=1
endif
#SPD: add for boost instagram draw threads priority by wei.kang 20230627 end

# TODO

http://jira.transsion.com/browse/X6850H895-5191 （滑动过程 出现卡内核函数， 转底层组）

滑动卡顿严重的时候都是出现卡内存down_read,需要内核组帮忙优化下这种情况



