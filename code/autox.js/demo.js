
auto.waitFor();
console.show();
let ocr_list = [];
let sor = 0;
let s1 = 0;
let ad_init = 0;//已经看完广告数量
let { detail_single_count, total_count, task_type, max_time, ad_count } = hamibot.env;
detail_single_count = detail_single_count;
total_count = total_count;
let read_list = ["", " "];
setScreenMetrics(1080, 1920);
console.log("T.T.Lite无障碍v0.0.5");



function scrollTouch(__count) {
    let r = random();
    for (let ___i = 0; ___i <= __count; ___i++) {
        gesture(500, [device.width / 2 + r, device.height / 2 + r], [device.width / 2 + r + r, device.height / 2 - 600 + r]);
        sleep(500);
    }

}

function detail() {
    let r = random();
    let c = 0;
    sleep(r * 1000);
    while (c <= parseInt(detail_single_count)) {
        gesture(500, [device.width / 2 + r, device.height / 2 + r], [device.width / 2 + r + r, device.height / 2 - 300 + r]);
        sleep(500 + r * 1000 * 2);
        c++;
    }
    sleep(r * 1000 * 2);

    sor++;
    console.log('看完第' + (sor) + '篇.')
    back();
}



//阅读文章
function task_article() {
    // 启动 
    launch('com.ss.android.article.lite');
   
    app.startActivity({
        packageName: 'com.ss.android.article.lite',
        className: 'com.ss.android.article.lite.activity.SplashActivity',
        root: false,
    });
    let refresh = text("首页").findOne(5000).parent();
    if(refresh)refresh.click();
    while (1) {

        let r = random();
        gesture(500, [device.width / 2 + r, device.height / 2 + r], [device.width / 2 + r + r, device.height / 2 - 600 + r]);
        sleep(100);

        let title = idMatches(/com.ss.android.article.lite:id\/(alx|b_|ci2|ci7|alv)/).find();

        //关闭广告
        let cl = className("com.lynx.tasm.behavior.ui.LynxFlattenUI").findOne(500)
        if (cl) {
            cl.click();
        }
        let ad4 = text("坚持退出").clickable(true).findOne(1500);
        if (ad4) {

            click(ad4.bounds().centerX(), ad4.bounds().centerY());
            sleep(300);

        }

        if (!title.empty()) {
            let _i = 0;
            let _list = title.toArray()
            console.log('发现' + _list.length + '个可阅读内容.')
            while (_i <= title.toArray().length) {

                if (_list[_i] && read_list.filter((v) => v === _list[_i].desc()).length === 0) {
                    read_list.push(_list[_i].desc())
                    if (_list[_i].click()) {
                        if (sor >= parseInt(total_count)) {
                            console.log('达到设置最大值。')
                            exit();
                        }
                        console.log("查看第" + (sor + 1) + '篇');
                        detail();
                    }
                }
                _i++;
            }
        }
    }

}


function ocr_tools() {


    console.log('处理OCR...');
    const img = captureScreen();
    console.log('识别结果中...')
    const res = ocr.recognize(img);
    return res.results;


}


function task_see_ads() {


    //逛一逛
    console.log('请先点开一个广告');
    console.log('看广告任务开始');
    sleep(35000);
    let cl = text("关闭").findOne(5000);
    if (cl) {
        cl.parent().click();
        let nextSee = textContains("看视频至多").findOne(3000);
        if (nextSee && ad_init <= ad_count) {
            nextSee.click();
            ad_init++
        } else {
            //关闭
            let exit_text = text("坚持退出").findOne(2000);
            if (exit_text) {
                exit_text.parent().click();
            }
            console.log('AD 任务完成');


        }

    }

}



function task_goods() {
    launch('com.ss.android.article.lite');
    app.startActivity({
        packageName: 'com.ss.android.article.lite',
        className: 'com.ss.android.article.lite.activity.SplashActivity',
        root: false,
    });

    sleep(1000);
    console.log('等待切换任务页面.')
    id("com.ss.android.article.lite:id/k3").waitFor();
    let toTask = text("任务").findOne(5000).parent();
    click(toTask.bounds().centerX(), toTask.bounds().centerY());
    sleep(1000);
    scrollTouch(4);
    sleep(3000);

    ocr_list = ocr_tools();
    //处理文本
    for (let oct of ocr_list) {

        //去逛逛
        if (oct.text === "去逛逛") {
            //逛一逛
            console.log('逛一逛开始');
            let open = press(oct.bounds.left + ((oct.bounds.right - oct.bounds.left) / 2), oct.bounds.top + ((oct.bounds.bottom - oct.bounds.top) / 2), 400);
            if (open) {
                console.log('逛逛任务开始');
                sleep(1000);
                scrollTouch(65);
                console.log('逛逛任务完成');
                sleep(1000);
                back();
            }

            break;

        }


    }


}

function init() {
    //阅读任务
    if (task_type === 'a') {

        task_article();
    }



    //逛一逛
    if (task_type === 'c') {
        task_goods();
    }


    //看广告
    if (task_type === 'd') {

        task_see_ads();
    }

}

if (task_type !== 'a') {

    var thread = threads.start(function () {
        //设置一个空的定时来保持线程的运行状态
        setInterval(function () { }, 1000);
    });
    //自动点击截图
    thread.setTimeout(function () {

        let s = text("立即开始").findOne(3000);
        if (s) s.click();
    }, 1000);
    if (!requestScreenCapture()) {
        console.log('没有授予 Hamibot 屏幕截图权限');
        hamibot.exit();
    }

}



init();