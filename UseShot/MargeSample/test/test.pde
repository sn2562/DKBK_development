boolean debugMode=false;//デバックモードがtrue時は自動的に上記のファイルをロードする。


String FilePath1;//始めにロードするデータとLキー押した時に読むデータのパスを入れ解くためのやつ(debug用)
String[] fp = new String[4];//複数ファイル名

//PVector[] points = new PVector[3];//マウスでクリックした三点
//int pointNum = 0;

final int K=2;//深度データ描写の細かさ
final int LENGTH=1145;//デプスデータを格納している配列の大きさ

final float screenZoom=1.2;//1.8;//描画範囲の倍率//1.5普段使い//1.2//微調整用
final int data_width=640;//画像の解像度
final int data_height=480;//画像の解像度

//boolean showTwoSketch = false;

static ArrayList<Data> data;//扱っているデータを格納しておく場所



int nowDataNumber;
PVector OAm, OBm, OCm;
boolean showTestMerge=false;

void setup() {
  frame.setTitle("DKBK");
  size(int(640*screenZoom), int(480*screenZoom), P3D);

  nowDataNumber=0;


  FilePath1=dataPath("")+"/13_40_51.dsd";

  //データの読み込み
  data=new ArrayList<Data>();
  data.add(new Data(FilePath1));//デバック用のデータ読み込み
  for (int i=0; i<fp.length; i++) {
    fp[i] = dataPath("")+"/body"+i+".dsd";
    println("fp " +i+"  "+fp[i]);
    data.add(new Data(fp[i]));//デバック用のデータ読み込み
  }

  //見え方を決める
  perspective(PI/4, float(width)/float(height), 10, 150000);//視野角は45度
  float z0 = (height/2)/tan(PI/8);//tan(radian(45/2))を使うと、微妙に数字がズレるのでダメ
  camera(width/2, height/2, z0, width/2, height/2, 0, 0, 1, 0);//カメラの位置を決める

  //  data.get(nowDataNumber).draw_mode=3;//非表示
  data.get(nowDataNumber).matrixReset();
}

void draw() {
  background(252, 251, 246);//キャンバス背景色
  if (showTestMerge) {
    data.get(1).update();
    data.get(2).update();
  } else {
    data.get(nowDataNumber).update();
  }
  frame.setTitle("DKBK");
}

void mousePressed() {
  //データとして位置を計算して返してもらう
  int num = data.get(nowDataNumber).pointNum;
  println("PCanvas "+num+" "+data.get(nowDataNumber).PCanvas(mouseX, mouseY));

  if (num<3) {
    data.get(nowDataNumber).points[data.get(nowDataNumber).pointNum]=data.get(nowDataNumber).PCanvas(mouseX, mouseY);
    data.get(nowDataNumber).pointNum++;
    //data.get(nowDataNumber).addPoint(mouseX, mouseY);
  } else if (num==3) {
    //三点のリセット
    for (int i=0; i<3; i++) {
      data.get(nowDataNumber).points[i]=new PVector(0, 0, 0);
    }
    data.get(nowDataNumber).pointNum=0;
  }
  println("mousePressed end");
}
void mouseReleased() {
}

//キーボードの操作
public void keyPressed(java.awt.event.KeyEvent e) {
  super.keyPressed(e);
  int dx=0, dy=0;
  println("keypressed "+e.getKeyCode());
  switch(e.getKeyCode()) {
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
    //  case '0':
    //    nowDataNumber=0;
    //    break;
  case '1':
    nowDataNumber=1;
    break;
  case '2':
    nowDataNumber=2;
    break;
  case '3':
    nowDataNumber=3;
    break;
  case '4':
    nowDataNumber=4;
    break;
  case 'S':
    //表示方法の切り替え
    int show = data.get(nowDataNumber).draw_mode;
    show++;
    if (show>=3)
      show=0;

    for (int i=0; i<data.size (); i++) {
      data.get(i).draw_mode=show;
    }
    break;

  case 'M':
    int sketch1=1;
    int sketch2=2;
    if (showTestMerge) {//表示設定担っている時はとりあえず非表示に設定する
      println("非表示");
      showTestMerge=false;
      data.get(sketch2).changeSketchView =false;
      data.get(sketch1).draw_mode=0;
      data.get(sketch2).draw_mode=0;
      showTestMerge=false;
    }

    if (data.get(1).pointNum!=3 || data.get(2).pointNum!=3) {//マージ用のポイントが揃っていなかったら中止
      println("点の数が足りません");
      break;
    }


    //両方表示する
    showTestMerge=!showTestMerge;//両方表示する

    if (showTestMerge) {//trueならば計算しなおして表示する
      println("計算を開始します");


      //軸にsketch1の軸を指定する
      //calcChangePosition();
      OAm=data.get(sketch1).calcChangeAxis()[0];
      OBm=data.get(sketch1).calcChangeAxis()[1];
      OCm=data.get(sketch1).calcChangeAxis()[2];
      PVector []ttt = data.get(sketch2).calcChangeAxis();

      println("OA "+OAm);
      println("OB "+OBm);
      println("OC "+OCm);

      //マージするsketch2の表示方法を変更する
      data.get(sketch2).changeSketchView = !data.get(sketch2).changeSketchView;
      //表示方法をかえる
      data.get(sketch1).draw_mode=2;
      data.get(sketch2).draw_mode=2;
    }
    break;
  }
  switch(e.getKeyCode()) {
  case '0':
    data.get(nowDataNumber).matrixReset();//全体移動
    break;
  case LEFT:
  case RIGHT:
  case UP:
  case DOWN://どれかの移動キーが押されているとき

    //    if (data.get(nowDataNumber).moveAble()) {
    println("いどう");
    //      if (!tool.moveWriter) {
    //        if (e.isShiftDown()) {
    //    data.get(nowDataNumber).rotate(dx*PI/100, dy*PI/100, 0);//全体移動-回転
    data.get(nowDataNumber).move(dx*100, dy*100);//全体移動-平行移動
    //        } else {
    //          data.get(tool.nowDataNumber).move(dx*100, dy*100);//全体移動-平行移動
    //          println("うごけー");
    //        }
    //      } else {
    //        if (e.isShiftDown())
    //          tool.rotate(dx*PI/100, dy*PI/100, 0);//単体移動-回転
    //        else
    //          tool.move(dx*100, dy*100);//単体移動-平行移動
    //    }
    //    }
    break;
  }
}

