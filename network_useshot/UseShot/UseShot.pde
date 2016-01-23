//2015.04.29 tomohiro
//更新のじどうか
import SimpleOpenNI.*;

String FilePath1, FilePath2;//始めにロードするデータとLキー押した時に読むデータのパスを入れ解くためのやつ(debug)
boolean debugMode=true;//デバックモード時は自動的に上記のファイルをロードする。
static boolean PCMode=true;//macの時...true

final int K=2;//深度データ描写の細かさ
final int LENGTH=1145;
final int data_width=640;//画像の解像度
final int data_height=480;//画像の解像度

final float screenZoom=1.5;//1.8;//描画範囲の調節用//1.5普段使い//1.2//微調整用

private TakeShot take;
private Tool tool;
private boolean pmousePressed;

static ArrayList<Data> data;

static int setLineW;//線の太さ
static boolean penMode=true;//ペンモード trueは普通ペン、falseは青ペン

static int animFrame;//フレームレートに沿ったフレーム数
static int frameset;//
static boolean animation;//アニメーションしてもいいかどうか
static int animMode;//アニメーションするときの表示方法を保存しておく
static int framecount=5;//設定するフレームカウント

SimpleOpenNI context;//カメラ更新用
static int oldToolNumber;

String getParentFilePath(String path, int n) {//n階層上のファイルパスを取得
  File f=new File(path);
  for (int i=0; i<n; i++)
    f=f.getParentFile();
  return f.getAbsolutePath();
}

void setup() {
  animFrame=frameset=0;
  animation=false;

  oldToolNumber=0;
  context = new SimpleOpenNI(this);//カメラ更新用
  // mirror is by default enabled
  context.setMirror(true);
  // enable depthMap generation 
  //  context.enableDepth();
  // enable ir generation
  //  context.enableRGB();
  context.setMirror(false);//鏡では表示しない

  frame.setTitle("DKBK");
  //size(1152, 864, P3D);
  float w=640*screenZoom;
  float h=480*screenZoom;
  size(int(w), int(h), P3D);

  //線の太さ、初期設定は3
  setLineW=7;

  //FilePath1=getParentFilePath(dataPath(""), 0)+"/TakeShot/data/yokoisanfront_2";
  FilePath1=dataPath("")+"/todai_horiken7.dsd";
  FilePath2=dataPath("")+"/todai_horiken7.dsd";

  tool=new Tool();
  take=new TakeShot(this);

  tool.nowToolNumber=0;//ツール初期設定

  data=new ArrayList<Data>();
  if (debugMode)
    data.add(new Data(FilePath1));//デバック用のデータ読み込み
  else
    data.add(new Data(true));//空のデータを入れておく

  perspective(PI/4, float(width)/float(height), 10, 150000);//視野角は45度
  float z0 = (height/2)/tan(PI/8);//tan(radian(45/2))を使うと、微妙に数字がズレるのでダメ
  //カメラの位置を決める
  camera(width/2, height/2, z0, width/2, height/2, 0, 0, 1, 0);

  printCamera();  
  pmousePressed=false;
  animMode=0;

  myclient = new MyClient(this);
}

void draw() {
//  frame.setTitle("DKBK "+round(frameRate) + " " + myclient.client_id + " " + myclient.friends.size());//
  frame.setTitle(String.format("DKBK speed:%03d/100 ID:%d member:%d", 
  round(100*frameRate/60), 
  myclient.client_id, 
  myclient.friends.size()));
  //フレームの計算
  if (tool.animMode()) {
    //アニメーション用フレームレート
    animFrame++;
    frameset=(animFrame-1)/framecount;
    //表示するデータ番号を出力

    //tool.nowDataNumberを変更する
    tool.nowDataNumber=frameset%data.size();
    println(frameset+":"+tool.moveWriter);

    //表示するデータを変更する draw_modeは0~3
    for (int i=0; i<data.size (); i++) {
      if (i==tool.nowDataNumber)//選択中のデータならば
        data.get(i).draw_mode=2;//0番の表示方法にあわせて表示
      else//それ以外
      data.get(i).draw_mode=3;//非表示
    }
  }

  tool.update();//ツールバーを更新
  background(252, 251, 246);//キャンバス背景色
  myclient.update();//通信用のクライアントを更新
  //if (!tool.isDragged&&!tool.isDragged2)//ツールバーに重なってないのなら
  //data.get(tool.nowDataNumber).draw();//線を描く

  //data.get(tool.nowDataNumber).addPoint(mouseX, mouseY);

  if (tool.getMode()) {//カメラモードでなければ
    context.update();//カメラ更新用
    //data内のデータを書き換える
    // data.get(tool.nowDataNumber).cameraChangeUpdate();
    //todo
    //useshot系データの描画
    for (int i=0; i<data.size (); i++) {//各種データの操作と描画
      data.get(i).update();
      //もし青ペンなら更新する
      //if (tool.nowToolNumber!=0&&tool.nowToolNumber!=4) {
      if (tool.nowToolNumber==1) {
        //        take.draw();
        //        take.save();//更新する
      }

      if (tool.getMovMode()) {
      } else {
        take.draw();
        take.save();//更新する
      }
    }
  } else {
    //takeshot系データの描画
    take.draw();
  }

  tool.draw();//ツールバーを描画

  pmousePressed=mousePressed;
}

void mousePressed() {
  //検証用
  //  println(tool.nowToolNumber);

  //切り替え

  //線の太さをペンのボタンで変更する
  if ( mouseButton == RIGHT ) //右ボタンが押されたときに太さを変更する
    setLineW=13;//右クリックしている時は太く
  else
    setLineW=13;//それ以外は細く

  if (tool.getMode()) {
    if (!tool.pointOver(mouseX, mouseY)) {//ツールバーに重なってないのなら
      data.get(tool.nowDataNumber).addLine();//線を追加
      //if ( mouseButton == RIGHT )//右クリックなら直線を描く用の始点を追加
      //data.get(tool.nowDataNumber).addPoint(mouseX, mouseY);
    }
  } else {//ツールバーに重なっていたら
    take.mousePressed();
  }

  if (tool.pointOver(mouseX, mouseY)) {//ツールバーに重なっている時
    //println("重なってる");
    /*
    if (oldToolNumber==tool.nowToolNumber) {//もし複数回クリックならば
     println("複数回クリック:number"+oldToolNumber);
     //data.get(tool.nowDataNumber).changeDrawMode();
     }
     */
  }
}

void mouseReleased() {
  //値を更新する
  //oldToolNumber=tool.nowToolNumber;
  // println("更新しました"+oldToolNumber+" "+tool.nowToolNumber);

  //直線を描く
  if (tool.getMode()) {
    if (!tool.isDragged&&!tool.isDragged2)//ツールバーに重なってないのなら
      switch(tool.nowToolNumber) {
      case 0://補正ペン
        /*
        println("直線");
         if ( mouseButton == RIGHT )
         data.get(tool.nowDataNumber).addPoint(mouseX, mouseY);
         */
        break;
      }
  }
}

void keyReleased(java.awt.event.KeyEvent e) {
  if (tool.getMode()) {
    super.keyReleased(e);//keyCodeやらを更新するために必要
    switch(e.getKeyCode()) {
    case LEFT:
    case UP:
    case RIGHT:
    case DOWN:
    case '0'://do
      //if (data.get(tool.nowDataNumber).moveAble())
      //data.get(tool.nowDataNumber).updateMap();//移動ボタンを離した時に射影しなおす
    }
  }
}

//マウスの操作
void mouseDragged() {

  if ( mouseButton == RIGHT ) //右ボタンが押されたときに太さを変更する
    setLineW=12;//右クリックしている時は太く
  else
    setLineW=12;//それ以外は細く

  //ツールごとの設定
  if (tool.getMode()) {
    if (!tool.isDragged&&!tool.isDragged2)//ツールバーに重なってないのなら
      switch(tool.nowToolNumber) {
      case 0://補正ペン
        //if ( mouseButton == RIGHT )
        //println("直線");
        //else
        data.get(tool.nowDataNumber).addPoint(mouseX, mouseY);
        break;
      case 1://スプレー改
        data.get(tool.nowDataNumber).addPoint(mouseX, mouseY);
        break;
      case 2://カッター
        data.get(tool.nowDataNumber).cutLine(pmouseX, pmouseY, mouseX, mouseY);
        break;
      case 4://移動
        println("移動ツール keyEvent:"+keyEvent);
        //検証用2
        if (keyEvent==null) {//起動直後
          //回転か並行かを判定する
          if (mouseButton == RIGHT) {
            //1.shiftが押されているか右クリックなら平行移動
            //平行移動
            if (!tool.moveWriter) {
              data.get(tool.nowDataNumber).move(mouseX-pmouseX, mouseY-pmouseY);
            } else {
              tool.move(mouseX-pmouseX, mouseY-pmouseY);
            }
          } else {
            //2.何もなしなら回転移動
            //回転移動
            if (!tool.moveWriter) {//全体移動
              data.get(tool.nowDataNumber).rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
            } else {//個々
              tool.rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
            }
          }
        } else if (keyEvent.isShiftDown()||mouseButton == RIGHT) {
          //3.shiftが押されているか右クリックなら平行移動
          //平行移動
          if (!tool.moveWriter) {
            data.get(tool.nowDataNumber).move(mouseX-pmouseX, mouseY-pmouseY);
          } else {
            tool.move(mouseX-pmouseX, mouseY-pmouseY);
          }
        } else {//何もしないなら回転移動
          //4.回転移動
          if (!tool.moveWriter) {//全体移動
            data.get(tool.nowDataNumber).rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
          } else {//個々
            tool.rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
          }
        }
        /*
        if (keyEvent==null||keyEvent.isShiftDown()||mouseButton == RIGHT) {//Shiftが押されているor右クリックなら移動。keyEvent==nullはキーボードが押されていなかった時をはじくための保険
         //println("tool.moveWriter "+tool.moveWriter);
         if (!tool.moveWriter) {
         data.get(tool.nowDataNumber).move(mouseX-pmouseX, mouseY-pmouseY);
         } else {
         tool.move(mouseX-pmouseX, mouseY-pmouseY);
         }
         } 
         //if (true) {//Shiftが押されていない時は回転
         else {
         if (!tool.moveWriter) {//全体移動
         data.get(tool.nowDataNumber).rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
         } else {//個々
         tool.rotate(radians(pmouseX-mouseX)/10, radians(pmouseY-mouseY)/10, 0);
         }
         }
         */
        /*
          else if (keyEvent==null||keyEvent.isControlDown()) {//controlが押されているならz軸で回転。
         if (!tool.moveWriter)//全体移動
         data.get(tool.nowDataNumber).rotate(0, 0, radians(pmouseY-mouseY)/10);
         else
         tool.rotate(0, 0, radians(pmouseY-mouseY)/10);
         } 
         */

        break;
      }
  }
}

//キーボードの操作
public void keyPressed(java.awt.event.KeyEvent e) {
  if (tool.getMode()) {
    tool.shortCut(e.getKeyCode());
    super.keyPressed(e);
    int dx=0, dy=0;
    switch(e.getKeyCode()) {//移動量を求める
    case LEFT:
      dx=-1;
      break;
    case RIGHT:
      dx=+1;
      break;
    case UP:
      dy=-1;
      break;
    case DOWN:
      dy=+1;
      break;
    }
    switch(e.getKeyCode()) {
    case '0':
      if (!tool.moveWriter)
        data.get(tool.nowDataNumber).matrixReset();
      else
        tool.matrixReset();
      break;
    case LEFT:
    case RIGHT:
    case UP:
    case DOWN://どれかの移動キーが押されているとき
      println("いどう");
      if (data.get(tool.nowDataNumber).moveAble()) {
        if (!tool.moveWriter) {
          if (e.isShiftDown()) {
            data.get(tool.nowDataNumber).rotate(dx*PI/100, dy*PI/100, 0);
          } else {
            data.get(tool.nowDataNumber).move(dx*100, dy*100);
            println("うごけー");
          }
        } else {
          if (e.isShiftDown())
            tool.rotate(dx*PI/100, dy*PI/100, 0);
          else
            tool.move(dx*100, dy*100);
        }
      }
      break;
    case DELETE://全消し
      data.get(tool.nowDataNumber).clear();
      break;
    case TAB://ツール表示しなおし
      tool.review();
      break;
    case 'S'://データの描画モードを変更
      data.get(tool.nowDataNumber).changeDrawMode();
      println("描画を変更 "+data.get(tool.nowDataNumber).draw_mode);
      break;
    case 'L'://ロード(debug用)
      if (debugMode&&data.size()==1)
        data.add(new Data(FilePath2));
      break;
    case 'P'://データをpcdとして書き出す
      println("make pcd data");
      break;

    case'T'://データの撮影
      println("takeShot!");
      take.save();
      break;

    case'A'://アニメーション
      animation=!animation;
      println("animationの切り替え animation:"+animation);
      //println("");
      break;
    case '1'://線の太さを変える
      setLineW=3;
      println("Line : 1");
      break;
    case '2':
      setLineW=5;
      println("Line : 2");
      break;
    case '3':
      setLineW=7;
      println("Line : 3");
      break;
    case '4':
      setLineW=9;
      println("Line : 4");
      break;
    case '5':
      setLineW=11;
      println("Line : 5");
      break;
    case '6':
      setLineW=13;
      println("Line : 6");
      break;

    case '8':
      data.get(tool.nowDataNumber).undo();
      break;

    case '9':
      data.get(tool.nowDataNumber).redo();
      break;


    default:
      break;
    }
  }
}

