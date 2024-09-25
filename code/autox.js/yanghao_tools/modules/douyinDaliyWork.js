(() => {
  const openApp = require('../utils/openApp')
  const { toIndexPage, videoLikeCommentCollect } = require('../utils/douyinUtils')
  const { strToNumber, randomRun, randomSwipe, randomSleep, liveSwipe } = require('../utils/util')
  const douyinClosePopup = require('../utils/douyinClosePopup')
  const storageDaliyConfig = require('../config/storageDaliy');

  function main () {
    // 打开抖音App
    openApp('抖音')
    // 拦截广告弹窗
    douyinClosePopup()
    // 切换到首页
    randomSleep(2000)
    toIndexPage()
    toastLog("等待页面加载完成")
    randomSleep(5000)

    // ======== 开始任务 ========
    toastLog("开始任务")
    startMission()
  }

  /**
   * 开始任务
   */
  function startMission () {
    // 判断是否直播间
    if (isLive()) {
      if (!storageDaliyConfig.isVisitLive()) {
        toastLog("遇到直播间，跳过")
        randomSwipe()
        randomSleep(1000)
        startMission()
        return
      }
      // 进入直播间 
      toastLog("进入直播间")
      desc("点击进入直播间按钮").visibleToUser().click()
      startLive()
    } else {
      startVideo()
    }
  }

  /**
   * 判断是否直播间
   * @returns {boolean} true 是直播间
   */
  function isLive () {
    return desc("点击进入直播间按钮").visibleToUser().exists()
  }
  /**
   * 是否达到 当次直播间关注上限
   * @returns {boolean} true 达到
   */
  function isArriveLiveFocusLimit () {
    const liveUserFocusLimit = storageDaliyConfig.liveUserFocusLimit() ? Number(storageDaliyConfig.liveUserFocusLimit()) : ''
    if (typeof liveUserFocusLimit === 'number' && currLiveUserFocusAmount >= liveUserFocusLimit) {
      return true
    }
    return false
  }
  /**
   * 是否达到 当日直播间关注上限
   * @returns {boolean} true 达到
   */
  function isArriveDayLiveFocusLimit () {
    const dayLiveUserFocusLimit = storageDaliyConfig.dayLiveUserFocusLimit() ? Number(storageDaliyConfig.dayLiveUserFocusLimit()) : '' // 关注限制
    const dayLiveUserFocusAmount = storageDaliyConfig.dayLiveUserFocusAmount() // 当前关注人数
    if (typeof dayLiveUserFocusLimit === 'number' && dayLiveUserFocusAmount >= dayLiveUserFocusLimit) {
      return true
    }
    return false
  }
  /**
   * 任务-进入直播间
   */
  let currVisitLiveAmount = 0 // 当前总完成了多少次直播间任务
  let liveUserWorkedList = [] // 已经处理过的用户
  let liveCommentWorkerList = [] // 已经处理过的用户评论
  let currLiveUserFocusAmount = 0 // 当前直播间已关注的用户
  function startLive () {
    currLiveUserFocusAmount = 0 // 每次进直播间重置一下
    randomSleep(1500)

    const liveAmount = storageDaliyConfig.liveAmount() // 要观看多少个直播间
    currVisitLiveAmount++
    if (currVisitLiveAmount > liveAmount) {
      toastLog("直播间任务总次数完成，退出")
      randomSleep(1000)
      quitLive()
      // 重新开始任务
      randomSwipe()
      toastLog("重新开始任务")
      randomSleep(2000)
      startMission()
      return
    }
    toastLog("开始直播间任务 " + currVisitLiveAmount + "/" + liveAmount)
    randomSleep(1000)

    try {
      // 直播已结束情况处理
      if (text("直播已结束").exists()) {
        toastLog("切换直播间，直播已结束")
        randomSleep(2000)
        startLive()
        return
      }

      // 直播间人数区间判断
      const liveMinPersonAmount = storageDaliyConfig.liveMinPersonAmount() ? Number(storageDaliyConfig.liveMinPersonAmount()) : 0
      let liveMaxPersonAmount = storageDaliyConfig.liveMaxPersonAmount() ? Number(storageDaliyConfig.liveMaxPersonAmount()) : 0
      if (liveMinPersonAmount || liveMaxPersonAmount) {
        const nowLivePersonAmountEl = id("com.ss.android.ugc.aweme:id/lqe").findOne(5000)
        const nowLivePersonAmount = nowLivePersonAmountEl ? Number(strToNumber(nowLivePersonAmountEl.text())) : ''
        log("直播间人数：", nowLivePersonAmount)
        if (typeof nowLivePersonAmount === 'number') { 
          if (!liveMaxPersonAmount) liveMaxPersonAmount = nowLivePersonAmount + 1
          if (nowLivePersonAmount < liveMinPersonAmount || nowLivePersonAmount > liveMaxPersonAmount) {
            toastLog("切换直播间，直播间人数不符合设定")
            nextLive()
            randomSleep(2000)
            startLive()
            return
          }
        }
      }
    } catch (error) {
      randomSleep(2000)
      startLive()
    }

    // 循环获取用户评论
    const loopLiveUserThreads = threads.start(function () {
      startLoopLiveUserMission()
    })

    const skipSeconds = random(Number(storageDaliyConfig.liveSkipMin()), Number(storageDaliyConfig.liveSkipMax()))
    toastLog(skipSeconds + '秒后切换下一个直播间')
    sleep(Number(skipSeconds) * 1000)
    const isOver = currVisitLiveAmount + 1 > liveAmount
    if (isOver) {
      startLive()
      return
    }

    loopLiveUserThreads.interrupt()
    randomSleep(1000)
    // 切换前判断用户界面弹窗是否还在打开，如果是则先关闭
    closeUserDataPopup()
    randomSleep(1000)
    toastLog('切换直播间，时间已到')
    nextLive()
    randomSleep(2000)
    startLive()
  }
  /**
   * 循环处理直播间评论用户任务
   * @description 针对直播间用户的筛选条件进行关注
   */
  function startLoopLiveUserMission () {
    try {
      // 当日直播间关注判断
      if (isArriveDayLiveFocusLimit()) {
        toastLog("已达到当日直播间关注上限")
        return
      }
      // 当次直播间关注判断
      if (isArriveLiveFocusLimit()) {
        toastLog("已达到当次直播间关注上限")
        return
      }

      const userEls = id("com.ss.android.ugc.aweme:id/text").find()
      userEls.forEach((val) => {
        // 当日直播间关注判断
        if (isArriveDayLiveFocusLimit()) return
        // 当次直播间关注判断
        if (isArriveLiveFocusLimit()) return
        
        const comment = val.text()
        const commentSplit = comment.split("：") // 分割评论内容

        // 已经处理过了 不继续执行
        if (liveCommentWorkerList.indexOf(comment) !== -1) {
          return
        }

        liveCommentWorkerList.push(comment)
        log('============= 评论 =============')
        log(commentSplit)
        /**
         * 正常来说一句用户评论的格式应该是 -> 用户用户：发送一个评论
         * 所以如果：分割后length只有1的话，通常不是正常的评论，可能是 Xxxx来了 或者 系统提示之类的
         * 所以只处理 length 为 2的评论
         */
        if (commentSplit.length === 2) {
          // 只点击未处理过的用户
          if (liveUserWorkedList.indexOf(commentSplit[0]) === -1) {
            // 打开用户个人信息
            const isClick = openUserDataPopup(val)
            if (!isClick) {
              return
            }
            // 打开成功则继续操作
            liveUserWorkedList.push(commentSplit[0])
            // 检测是否不允许查看个人信息，是则跳过直播间
            if (text("因主播设置，暂不支持查看个人信息").exists()) {
              text("取消").click()
              randomSleep(500)
              toastLog("切换直播间，主播设置不允许查看信息")
              nextLive()
              randomSleep(2000)
              return
            }
            // 检测用户是否达到设置的条件
            const userData = findLiveUserData()
            log('用户：', commentSplit[0])
            log('关注数：', userData.focusAmount)
            log('粉丝数：', userData.fansAmount)
            log('年龄：', userData.userAge)
            log('城市：', userData.userArea)
            log('性别：', userData.userGender)
            log('学校：', userData.userSchool)
            // 性别flag
            const liveUserGender = storageDaliyConfig.liveUserGender()
            const genderFlag = !liveUserGender ? true : liveUserGender === userData.userGender
            // 关注数flag
            const liveUserFocusMin = storageDaliyConfig.liveUserFocusMin() ? Number(storageDaliyConfig.liveUserFocusMin()) : 0
            const liveUserFocusMax = storageDaliyConfig.liveUserFocusMax() ? Number(storageDaliyConfig.liveUserFocusMax()) : Number(userData.focusAmount) + 1
            const focusFlag = Number(userData.focusAmount) > liveUserFocusMin && Number(userData.focusAmount) < liveUserFocusMax
            // 粉丝数flag
            const liveUserFansMin = storageDaliyConfig.liveUserFansMin() ? Number(storageDaliyConfig.liveUserFansMin()) : 0
            const liveUserFansMax = storageDaliyConfig.liveUserFansMax() ? Number(storageDaliyConfig.liveUserFansMax()) : Number(userData.fansAmount) + 1
            const fansFlag = Number(userData.fansAmount) > liveUserFansMin && Number(userData.fansAmount) < liveUserFansMax
            // 区域flag
            const liveUserArea = storageDaliyConfig.liveUserArea()
            const areaFlag = !liveUserArea ? true : userData.userArea.indexOf(liveUserArea) !== -1

            log('性别', genderFlag, '关注数', focusFlag, '粉丝数', fansFlag, '区域', areaFlag)
            // 满足所有条件，关注
            if (genderFlag && focusFlag && fansFlag && areaFlag) {
              if (desc("关注 按钮").exists() && randomRun(0.8)) {
                desc("关注 按钮").click()
                currLiveUserFocusAmount++ // 当次直播间关注数+1
                storageDaliyConfig.storageDaliy.put('dayLiveUserFocusAmount', Number(storageDaliyConfig.dayLiveUserFocusAmount()) + 1) // 当日直播间关注数+1
              }
            }
            randomSleep(1000)
            closeUserDataPopup()
            randomSleep(2000)
          }
        }
      })
      // 重新执行-循环处理直播间评论用户
      randomSleep(1500)
      startLoopLiveUserMission()
    } catch (error) {
      log("【Error】LoopLiveUserMain ======= ", error)
    }
  }
  /**
   * 打开用户信息弹窗
   * @returns 
   */
  function openUserDataPopup (el) {
    const isClick = el.click()
    if (isClick) {
      log("已打开用户信息弹窗")
      randomSleep(500)
    }

    log("是否成功打开弹窗", isClick)

    return isClick
  }
  /**
   * 关闭用户信息弹窗
   * @returns 
   */
  function closeUserDataPopup () {
    if (id("com.ss.android.ugc.aweme:id/q=p").visibleToUser().exists()) {
      if (id("com.ss.android.ugc.aweme:id/re=").visibleToUser().exists()) {
        id("com.ss.android.ugc.aweme:id/re=").visibleToUser().findOne().click()
        log("已关闭用户信息弹窗")
        randomSleep(500)
      }
    }
  }
  /**
   * 获取用户数据
   * @returns 
   */
  function findLiveUserData () {
    try {
      log("开始获取用户数据")

      // 关注数、粉丝数
      let focusAmount = 0
      let fansAmount = 0
      const focusFansEl = id("com.ss.android.ugc.aweme:id/ld9").visibleToUser().findOne(4000)
      if (focusFansEl) {
        const focusFansSplit = focusFansEl.text().split(' · ')
        if (focusFansSplit.length === 2) {
          focusAmount = Number(strToNumber(focusFansSplit[0].split(' 关注')[0]))
          fansAmount = Number(strToNumber(focusFansSplit[1].split(' 粉丝')[0]))
        }
      }

      let userAge = ''
      let userArea = ''
      let userGender = ''
      let userSchool = ''
      id("com.ss.android.ugc.aweme:id/m7c").visibleToUser().find().forEach((val) => {
        const valText = val.text()
        if (valText.indexOf('岁') !== -1) {
          // 年龄
          userAge = valText.split('岁')[0]
        } else if (valText === '女' || valText === '男') {
          // 性别
          userGender = valText
        } else if ((/小学|初中|中学|大学|学院|职业|毕业/g).test(valText)) {
          // 学校
          userSchool = valText
        } else if (valText && valText.length <= 8) {
          // 城市名一般不会太长 所以限制 8个字符之内
          // 暂时默认为城市
          userArea = valText
        }
      })

      return {
        focusAmount: focusAmount,
        fansAmount: fansAmount,
        userAge: userAge,
        userArea: userArea,
        userGender: userGender,
        userSchool: userSchool,
      }
    } catch (error) {
      log("【Error】FindLiveUserData ======= ", error)
    }
  }
  /**
   * 切换下一个直播间
   */
  function nextLive () {
    toastLog("当次直播间关注了 " + currLiveUserFocusAmount + " 人")
    liveSwipe()
  }
  /**
   * 退出直播间
   */
  function quitLive () {
    // 退出前判断弹窗是否打开
    closeUserDataPopup()
    // 退出直播间
    id("com.ss.android.ugc.aweme:id/chw").findOne().click()
    toastLog("退出直播间")

    // 重置数据
    currVisitLiveAmount = 0
    liveUserWorkedList = []
    liveCommentWorkerList = []

    randomSleep(3000)
  }

  /**
   * 任务-作品点赞评论收藏
   */
  function startVideo () {
    videoLikeCommentCollect({
      videoSkipMin: storageDaliyConfig.videoSkipMin,
      videoSkipMax: storageDaliyConfig.videoSkipMax,
      likeMin: storageDaliyConfig.likeMin,
      likeMax: storageDaliyConfig.likeMax,
      collectMin: storageDaliyConfig.collectMin,
      collectMax: storageDaliyConfig.collectMax,
      commentMin: storageDaliyConfig.commentMin,
      commentMax: storageDaliyConfig.commentMax,
      commentContent: storageDaliyConfig.commentContent,
    }, () => {
      startMission()
    })
  }

  module.exports = main
})();