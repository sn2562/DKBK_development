//撮影したら自動保存
// path/Users/kawasemi/Dropbox/intraction/***.dsd
//

import java.awt.FileDialog;
import java.io.*;

public class Data {//DepthDatadrawを並列処理にすれば軽くなるか？
  //三点
  public PVector[] points = new PVector[3];//マウスでクリックした三点
  private int pointNum = 0;
  public boolean changeSketchView = false;
  //計算用
  PVector OA, OB, OC;

  private PVector pos;
  private float rotX, rotY, rotZ;//回転量
  private int draw_mode;//写真と線を表示(0) 線だけ表示(1) 深度と線を表示(2) 表示なし(3) 

  private PImage img;
  private int [] depthMap;
  private PVector[] realWorldMap, realWorldMap_back;
  private ArrayList<DT> lines, undo;

  int repoint;//補正を開始した場所(添字)

  public boolean loadAbled=false;//ロードに成功したかどうか。falseのときArrayList<Data>から削除する
  public boolean defaultData=false;//空のデータであるかどうか。
  public boolean shouldupdate=false;//回転、移動等したかどうか。射影するときに使う
  private float RotateMatrix[]=new float[16];//X軸での回転のための行列

  private PVector[] projectionMap;//projectionMapは回転後を見るために使う
  public String dataname="";

  private String Savepath="/Users/kawasemi/Desktop/dsdData/";//mac版/選択したファイル
  //private String Savepath="C:\\Users\\imlab\\Desktop\\dsdData\\kikuchi"+year()+month()+day()+hour()+"_"+minute()+"_"+second()+".dsd";//windows版
  //private String Savepath="C:\\Users\\sumi_000\\Desktop\\dsdData\\oikawa"+year()+month()+day()+hour()+"_"+minute()+"_"+second()+".dsd";//windows版

  private void ready() {
    realWorldMap_back=new PVector[realWorldMap.length];
    projectionMap=new PVector[realWorldMap.length];

    for (int i=0; i<realWorldMap.length; i++) {
      realWorldMap_back[i]=new PVector();
      realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);

      projectionMap[i]=new PVector();
      projectionMap[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
    }

    undo=new ArrayList<DT>();

    //三点のリセット
    for (int i=0; i<3; i++) {
      points[i]=new PVector(0, 0, 0);
    }  

    draw_mode=0;
    matrixReset();
  }

  private PVector calcNVector(PVector[] p) {//3点からなる面の法線ベクトルを返す
    //if (p.length!=3)return new PVector(0, 0, 0);

    PVector AB = PVector.sub(p[1], p[0]);
    PVector AC = PVector.sub(p[2], p[0]);
    PVector n= AB.cross(AC);//法線ベクトル
    n.normalize();//法線ベクトルの正規化
    //  n.mult(1000);//法線ベクトルのスカラー倍

    return n;
  }



  public PVector[] calcChangeAxis() {
    //三点から三軸を計算して格納する
    //基準の3軸
    OA = PVector.sub(points[1], points[0]);
    OA.normalize();

    OB = PVector.sub(points[2], points[0]);

    OC = calcNVector(points);//法線ベクトルを計算する
    OC.normalize();

    //OBは垂直になるように再計算する
    OB = OA.cross(OC);//法線ベクトル
    OB.normalize();
    PVector[] ans = {
      OA, OB, OC
    };

    return ans;
  }
  public PVector calcChangePosition(PVector x) {//任意の点xを受け取ったら位置変換後の場所を返す
    //println("calcChangePositionを実行 ベクトルx="+x);
    //計算用
    float[][] value = new float[3][4];//計算前の係数
    float calcAns[] = new float[3];//計算結果 αβγ

    //計算用の係数をセットする
    value[0][0]=x.x;
    value[0][1]=OA.x;
    value[0][2]=OB.x;
    value[0][3]=OC.x;

    value[1][0]=x.y;
    value[1][1]=OA.y;
    value[1][2]=OB.y;
    value[1][3]=OC.y;

    value[2][0]=x.z;
    value[2][1]=OA.z;
    value[2][2]=OB.z;
    value[2][3]=OC.z;

    //GaussJordan法で連立方程式を解く
    int michisu=3;//未知数の数

    for (int m=0; m<michisu; m++) {
      int chu = m;//注目式の番号
      if (value[chu][chu+1]==0) {
        break;//0除算を避ける
      }

      //注目式の未知数の係数を1にする
      float div = value[chu][chu+1];//値が途中で変わってしまうのでとっておく
      for (int i=0; i<4; i++) {
        value[chu][i] =value[chu][i]/div;
      }

      if (m==michisu-1)break; //最後の計算まで終わったらfor文を抜ける

      //注目式以外のβの係数を0にする
      for (int i=0; i<3; i++) {
        if (i!=chu) {//注目式以外
          div = value[i][chu+1];//値が途中で変わってしまうのでとっておく
          for (int j=0; j<4; j++) {//４つの係数全てに対して計算を行う
            value[i][j]=value[i][j] - div*value[chu][j];//
          }
        }
      }
    }

    //γの値は20
    //βの値は10-13*γ
    //αの値は00-02*β-03*γ
    calcAns[2]=value[2][0];//γ
    calcAns[1]=value[1][0]-value[1][3]*calcAns[2];//β
    calcAns[0]=value[0][0]-value[0][3]*calcAns[2];//
    //    println("(α β γ) = ("+calcAns[0]+" "+calcAns[1]+" "+calcAns[2]+")");

    //x=αOA+βOB+γOC
    PVector ax, ay, az;
    ax=PVector.mult(OAm, calcAns[0]);
    ay=PVector.mult(OBm, calcAns[1]);
    az=PVector.mult(OCm, calcAns[2]);
    PVector ansPosition = PVector.add(ax, ay);
    ansPosition.add(az);
    //
    //    println("---");
    //    println(ansPosition);

    //全体を平行移動してOA点の位置をあわせる
    //    x.normalize();
    //    PVector subVector = PVector.sub(OAm, OA);//OAmはノーマライズされてるのでこれではダメかも...
    //    println("subVector "+subVector);
    //    ansPosition=PVector.add(ansPosition, subVector);


    return ansPosition;
  }


  public Data(boolean t) {//空のデータを入れるためのコンストラクタ
    frame.setTitle("DKBK Now Loading...");
    defaultData=true;

    pos=new PVector();
    lines=new ArrayList<DT>();
    PGraphics g=createGraphics(640, 480);//疑似画像を作る
    //    g=createGraphics(width, height);//サイズが640*480意外だとずれる
    g.beginDraw();
    g.background(252, 251, 246);
    g.endDraw();
    img=g;
    depthMap=new int[img.width*img.height];
    realWorldMap=new PVector[img.width*img.height];
    for (int i=0; i<realWorldMap.length; i++)//深度情報ナシでdepthDataを作成
      realWorldMap[i]=new PVector();

    loadAbled=true;

    ready();
  }

  public Data() {//選択ダイアログを開いて読み込み
    frame.setTitle("DKBK Now Loading...");
    FileDialog fd=new FileDialog(frame, "ファイルを選択してください", FileDialog.LOAD);
    //    fd.setFilenameFilter(getFileExtensionFilter(".dsd"));
    fd.setVisible(true);
    if (fd.getFile()==null||fd.getFile().length()==0)
      return;

    String path=fd.getDirectory()+fd.getFile();
    pos=new PVector();
    lines=new ArrayList<DT>();
    if (!load(path)) return;
    loadAbled=true;

    ready();
  }

  //takeshotのデータをそのまま読み込む
  public Data(PImage timg, int tdepthMap[], PVector[] trealWorldMap) {//takeshotのデータをそのまま読み込む
    println("takeshotのデータをそのまま読み込む");
    //frame.setTitle("DKBK Now Loading...");
    pos=new PVector();
    lines=new ArrayList<DT>();

    loadAbled=true;

    //うけとった要素を代入して初期化
    img=timg;
    depthMap=new int[img.width*img.height];
    realWorldMap=new PVector[img.width*img.height];
    realWorldMap_back=new PVector[img.width*img.height];
    for (int i=0; i<tdepthMap.length; i++) {
      //println("depthmapを再構築");
      depthMap[i]=tdepthMap[i];
    }

    for (int i=0; i<trealWorldMap.length; i++) {
      realWorldMap[i]=trealWorldMap[i];
    }

    for (int i=0; i<realWorldMap.length; i++) {
      realWorldMap_back[i]=new PVector();
      realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
    }

    ready();
  }


  public Data(String path) {//パスを直接指定して読み込み
    frame.setTitle("DKBK Now Loading...");
    pos=new PVector();
    lines=new ArrayList<DT>();
    if (!load(path)) return;
    loadAbled=true;


    ready();
  }

  public int getW() {
    return img.width;
  }
  public int getH() {
    return img.height;
  }
  public PVector getVector(int idx) {
    return realWorldMap_back[idx];
  }

  public void draw() {
    //    color penColor=tool.getPenColor();
    //    int penW=tool.getPenWeight();
    //    int penT=tool.getPenTool();

    color penColor = #FFCC00;
    int penW = 3;
    int penT=1;

    fill(#ff0000);
    ellipse(0, 0, 100, 100);


    if (mousePressed) {
      switch(penT) {
      case 1://スプレー
        break;
      case 3://深度スポイト
        float sum=0;
        int x=(int)map(mouseX, 0, width, 0, img.width);//マウスのx座標をイメージ画像上の位置に変換
        int y=(int)map(mouseY, 0, height, 0, img.height);//マウスのy座標をイメージ画像上の位置に変換
        int n=0;//深度が存在した点の数
        for (int iy=-10; iy<=10; iy++)//iy<10まで(まわりの値もとるため)
          for (int ix=-10; ix<=10; ix++) {//ix<10まで(まわりの値もとるため)
            if (0<=x+ix&&x+ix<img.width&&0<=y+iy&&iy+y<img.height) {//画像範囲内のときだけ処理を実行
              //              if (depthMap[(y+iy)*img.width+(x+ix)]!=0) {
              if (realWorldMap[(y+iy)*img.width+(x+ix)].z!=0) {//データがあれば
                //                sum+=depthMap[(y+iy)*img.width+(x+ix)];
                if (mouseButton==LEFT)
                  sum+=realWorldMap[(y+iy)*img.width+(x+ix)].z;//もしクリックしたらsum値を変更
                else
                  sum+=myScreenZ(realWorldMap[(y+iy)*img.width+(x+ix)].x, realWorldMap[(y+iy)*img.width+(x+ix)].y, realWorldMap[(y+iy)*img.width+(x+ix)].z);
                n++;
              }
            }
          }
        if (n>0) {
          //tool.setSpoit(sum/n);//平均値を算出して出力
        }

        break;
      }
    }
  }

  public void redo() {//元に戻す
    if (lines.size()==0)return;
    DT d=lines.get(lines.size()-1);
    if (d.getClass().toString().contains("Cut")) {//最後のがカットデータ
      int n=((Cut)d).getN();
      lines.get(n).addAll(lines.remove(n+1));//前のと後ろのを結合
    }
    undo.add(0, lines.remove(lines.size()-1));
  }
  public void undo() {//やり直し
    if (undo.size()>0)
      lines.add(undo.remove(0));
  }
  public void clear() {//全消去
    lines.clear();
  }
  public void undoclear() {
    undo.clear();
  }

  private void updateMap() {
    pushMatrix();
    setMatrix();
    for (int i=0; i<realWorldMap.length; i++)
      realWorldMap[i].set(0, 0, 0);
    for (PVector p : realWorldMap_back) {
      if (p.z==0)continue;
      int x=round(map(screenX(p.x, p.y, p.z), 0, width, 0, img.width));
      int y=round(map(screenY(p.x, p.y, p.z), 0, height, 0, img.height));
      if (0<=x&&x<img.width&&0<=y&&y<img.height) {
        int idx=x+y*img.width;
        realWorldMap[idx].set(p.x, p.y, p.z);
      }
    }
    popMatrix();
  }
  public void move(float x, float y) {
    shouldupdate=true;
    switch(0) {
    case 0:
      pos.x+=x*cos(rotY)+y*sin(rotY);
      pos.z+=x*sin(rotY)-y*cos(rotY);
      break;
    case 1:
      pos.x+=x*cos(rotY);
      pos.z+=x*sin(rotY);
      pos.y+=-y;
      break;
    }
  }
  public void rotate(float dy, float dx, float dz) {
    shouldupdate=true;
    rotX+=dx;
    rotY+=dy;
    rotZ+=dz;
  }
  public void matrixReset() {//移動量をリセットする
    shouldupdate=true;
    pos.set(0, 0, 0);
    rotX=PI;
    rotZ=0;
    rotY=0;
  }
  public boolean isDefaultPosition() {//移動してないかどうか。sinを使っているのは計算誤差を許容するため
    return pos.x==0&&pos.y==0&&pos.z==0&&abs(sin(rotX-PI))<0.01&&abs(sin(rotY-0))<0.01;
  }

  public void setMatrix() {//移動量を反映
    translate(width/2, height/2);
    rotateX(rotX);
    rotateY(rotY);
    rotateY(rotZ);
    scale(0.575f*width/img.width);
    translate(0, 0, -1000);
    translate(pos.x, pos.y, pos.z);
  }

  public void cameraupdate(PImage timg, int tdepthMap[], PVector[] trealWorldMap) {
    //frame.setTitle("DKBK Now Loading...");
    pos=new PVector();
    //linesの初期化はしない
    //lines=new ArrayList<DT>();
    //うけとった要素を代入して初期化
    img=timg;
    depthMap=new int[img.width*img.height];
    realWorldMap=new PVector[img.width*img.height];
    realWorldMap_back=new PVector[img.width*img.height];
    for (int i=0; i<tdepthMap.length; i++) {
      //println("depthmapを再構築");
      depthMap[i]=tdepthMap[i];
    }

    for (int i=0; i<trealWorldMap.length; i++) {
      realWorldMap[i]=trealWorldMap[i];
    }


    for (int i=0; i<realWorldMap.length; i++) {
      realWorldMap_back[i]=new PVector();
      realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
    }
  }

  public void cameraChangeUpdate(PImage timg, int tdepthMap[], PVector[] trealWorldMap) {
    //現在の値を新しいカメラの値で描き換える

    //frame.setTitle("DKBK Now Loading...");
    pos=new PVector();
    //linesの初期化はしない
    //lines=new ArrayList<DT>();
    //うけとった要素を代入して初期化
    img=timg;
    depthMap=new int[img.width*img.height];
    realWorldMap=new PVector[img.width*img.height];
    realWorldMap_back=new PVector[img.width*img.height];
    for (int i=0; i<tdepthMap.length; i++) {
      //println("depthmapを再構築");
      depthMap[i]=tdepthMap[i];
    }

    for (int i=0; i<trealWorldMap.length; i++) {
      realWorldMap[i]=trealWorldMap[i];
    }


    for (int i=0; i<realWorldMap.length; i++) {
      realWorldMap_back[i]=new PVector();
      realWorldMap_back[i].set(realWorldMap[i].x, realWorldMap[i].y, realWorldMap[i].z);
    }
  }

  public void update() {
    pushMatrix();
    if (draw_mode==3) {
      //非表示の時に行いたい処理
    }

    if (draw_mode==0) {
      hint(DISABLE_DEPTH_TEST);//二次元描画モード
      //画像を描画-ただし、さっきまで画面に表示されていたカメラの写真に変更されている
      //半透明にする
      tint(255, 120);
      image(img, 0, 0, width, height);
      //透明度を元に戻す
      tint(255, 255);
      hint(ENABLE_DEPTH_TEST);//終了
    }

    setMatrix();
    //他のデータも更新する

    if (draw_mode==2) {
    }
    if (draw_mode!=3) {
      drawLine();
      drawCube();
    }
    popMatrix();

    //todo
    pushMatrix();
    setMatrix();


    if (draw_mode==2) {
      drawDepthData();
    }
    popMatrix();
  }

  public void calcPoint() {
  }

  public void addLine() {//mousePressed時に呼ぶ
  }

  public boolean moveAble() {
    return draw_mode!=0;
  }
  public void changeDrawMode() {
    draw_mode=(draw_mode+1)%4;
  }

  private void drawLine() {//TODO : 新しい位置を計算する
    noFill();
    for (DT line : lines) {
      //if (!line.ableDraw())continue;
      stroke(line.c);
      strokeWeight(line.w);
      if (line.beginShape()==-1)
        beginShape();
      else
        beginShape(line.beginShape());
      for (PVector p : line) {
        if (changeSketchView)//マージが設定されていたら
          p = calcChangePosition(p);

        vertex(p.x, p.y, p.z);
        vertex(p.x, p.y, p.z);//vertex一回だとなぜか線をsize()==2の時なぜか線を書いてくれない
      }
      endShape();
      //drawArea();
      strokeWeight(1);
    }
    //    if (changeSketchView)//マージが設定されていたら
    //      println("end drawLine");
  }
  private void drawCube() {

    for (int i=0; i<3; i++) {

      float x=points[i].x;
      float y=points[i].y;
      float z=points[i].z;
      PVector p=new PVector(x, y, z);

      if (changeSketchView) {//マージが設定されていたら
        p = calcChangePosition(p);
      }

      pushMatrix();
      translate(p.x, p.y, p.z);
      if (i==0)
        fill(#ff0000);
      if (i==1)
        fill(#00ff00);
      if (i==2)
        fill(#0000ff);
      noStroke();
      float box=p.z;
      box(box/94, box/94, box/94); 
      popMatrix();
    }
  }

  private void drawDepthData() {//深度データを描画する
    int K;
    if (changeSketchView)
      K=4;//マージが設定されていたら
    else
      K=4;
    strokeWeight(K);
    for (int y=0; y < img.height; y+=K) {
      for (int x=0; x < img.width; x+=K) {
        int index = x + y * img.width;
        PVector p=realWorldMap_back[index];
        if (p.z > 0) { 
          stroke(img.pixels[index]);

          if (changeSketchView)//マージが設定されていたら
            p = calcChangePosition(p);
          point(p.x, p.y, p.z);  // make realworld z negative, in the 3d drawing coordsystem +z points in the direction of the eye
        }
      }
    }
    //    if (changeSketchView)//マージが設定されていたら
    //      println("end drawDepthData");
    strokeWeight(1);
  }
  public PVector PCanvas(int x, int y) {

    try {//たまにArrayIndexOutOfBoundsExceptionでるのでその例外をはじいておく。
      //      if (tool.pointOver(x, y)) return new PVector(0, 0, 0);//ツールバーに重なってないなら続ける
      boolean dp=isDefaultPosition();
      x=(int)map(x, 0, width, 0, img.width);//マウス座標を画像上の位置に変換する
      y=(int)map(y, 0, height, 0, img.height);
      if (x<0||y<0||x>width||y>height)return  new PVector(0, 0, 0);//画面外に書いていたら何もしない
      int idx=x+y*img.width;//マウス位置を計算する
      if (idx<0||idx>realWorldMap.length)return new PVector(0, 0, 0);//配列の範囲外だったら何もしない
      PVector p=new PVector();//追加するベクトル
      p.set(realWorldMap_back[idx].x, realWorldMap_back[idx].y, realWorldMap_back[idx].z);

      return p;
    }
    catch(Exception e) {
      println("check Exception e");
      println(frameCount, x, y);
      e.printStackTrace();
    }
    println("ダミーを返す");
    return new PVector(0, 0, 0);//ダミー
  }


  private void addPoint(int x, int y) {//マウスの座標が入る

    try {//たまにArrayIndexOutOfBoundsExceptionでるのでその例外をはじいておく。
      //      if (tool.pointOver(x, y)) return;//ツールバーに重なってないなら続ける
      boolean dp=isDefaultPosition();
      x=(int)map(x, 0, width, 0, img.width);//マウス座標を画像上の位置に変換する
      y=(int)map(y, 0, height, 0, img.height);
      if (x<0||y<0||x>width||y>height)return;//画面外に書いていたら何もしない
      int idx=x+y*img.width;//マウス位置を計算する
      if (idx<0||idx>realWorldMap.length)return;//配列の範囲外だったら何もしない
      PVector p=new PVector();//追加するベクトル
      p.set(realWorldMap_back[idx].x, realWorldMap_back[idx].y, realWorldMap_back[idx].z);

      ArrayList<PVector>line=lines.get(lines.size()-1);//一番最後の線
      if (p.z==0) {

        if (!(pos.x==0&&pos.y==0&&pos.z==0&&abs(sin(rotX-PI))<0.01&&abs(sin(rotY-PI))<0.01)) {//もし移動されていたら、位置を計算しなおして入れとく
        } else {
          p=calcRealPoint(LENGTH*5, x, y);
        }
      }
    }
    catch(Exception e) {
      println(frameCount, x, y);
      e.printStackTrace();
    }
  }

  private boolean load(String path) {
    try {
      //もし読み込みファイルが.dsd.pngで終わるようならば.pngを消して読み込みしてみる
      boolean userImage=false;

      if (path.endsWith(".dsd.png")) {
        println("画像の読み込みです");
        path = path.replaceAll(".png", "");
        userImage=true;
      }

      File f=new File(path);

      if (!f.exists()) {
        System.err.println("読み込みに失敗しました。");
        System.err.println(f.getAbsolutePath()+"\nは存在しません。");
        return false;
      }

      if (!f.canRead()) {
        System.err.println("読み込みに失敗しました。");
        System.err.println("読み込むことのできないファイルです。");
        return false;
      }

      String[] splitpath = splitTokens(path, "/");
      println("dataname2 "+splitpath[splitpath.length-1]);
      dataname=splitpath[splitpath.length-1];     


      ObjectInputStream is=new ObjectInputStream(new FileInputStream(f));

      //ファイルからオブジェクトを読み込む
      int w=(Integer)is.readObject();
      int h=(Integer)is.readObject();
      color c[]=(color[])is.readObject();
      depthMap=(int[])is.readObject();
      realWorldMap=(PVector[])is.readObject();
      if (path.endsWith("dsd")) {
        int n=(Integer)is.readObject();
        for (int i=0; i<n; i++) {
          int m=(Integer)is.readObject();
          color cc=(Integer)is.readObject();
          int ww=(Integer)is.readObject();
          DT line=new DT(cc, ww);
          switch(m) {
          case 0:
            line=new Line(cc, ww);
            break;
          case 1:
            line=new Spray(cc, ww);
            break;
          }
          line.addAll((ArrayList<PVector>)is.readObject());
          lines.add(line);
        }
      }

      img=createImage(w, h, ARGB);//画像を扱うためのバッファを作る
      println("つくったがぞうさいず"+w+" "+height);
      img.pixels=c;//バッファの色データを読み込んだオブジェで書き換える


      //得られた情報から画像データを作成
      if (userImage) {//選択データが画像だった時
        //img = loadImage(path+".png");
        PImage testImg = loadImage(path+".png");
        testImg.resize(w, h);
        println("画像サイズ "+testImg.width+" "+testImg.height);
        img.pixels=testImg.pixels;
      } else {
        img.pixels=c;
      }

      is.close();//使い終わったら閉める

      return true;
    }
    catch(Exception e) {
      System.err.println("読み込みに失敗しました。");
      e.printStackTrace();
      return false;
    }
  }
  private void save() {
    frame.setTitle("保存中");
    try {
      //FileDialogで読み込みたいファイルを選択する
      FileDialog fd=new FileDialog(frame, "ファイルを選択してください", FileDialog.SAVE);
      fd.setFilenameFilter(getFileExtensionFilter(".dsd"));
      if (debugMode)
        fd.setFile("test.dsd");
      else
        fd.setFile("*.dsd");
      fd.setVisible(true);
      String path=fd.getDirectory()+fd.getFile();//選択したファイル

      //決定が押されてなかったり、ファイル名の長さが0だったりしたら、出力を中断
      if (fd.getFile()==null||fd.getFile().length()==0)
        return;
      if (!path.endsWith("dsd"))//拡張子をdsdに強制
        path+=".dsd";

      ObjectOutputStream os=new ObjectOutputStream(new FileOutputStream(new File(path)));
      println("保存-path"+path);

      //ファイルにオブジェクトを書き込む
      os.writeObject(img.width);
      os.writeObject(img.height);
      img.loadPixels();
      os.writeObject(img.pixels);
      os.writeObject(depthMap);
      os.writeObject(realWorldMap_back);

      int i=0;
      for (DT line : lines) {
        if (line.getSaveMode()==-1)continue;
        i++;
      }
      os.writeObject(i);
      println("iの値を表示"+i);
      i=0;
      for (DT line : lines) {
        //タイプ(line or spray)//
        int n=line.getSaveMode();
        if (n==-1)continue;
        os.writeObject(n);
        //タイプ
        os.writeObject(line.getColor());//色
        os.writeObject(line.getWeight());//太さ
        ArrayList<PVector>l=new ArrayList<PVector>();
        l.addAll(line);
        os.writeObject(l);//線データ
        i++;
      }
      println("iの値を表示"+i);
      os.close();//使い終わったら閉める

      //画像も保存する
      img.save(path+".png");
    }
    catch(Exception e) {
      System.err.println("書き込みに失敗しました。");
      e.printStackTrace();
    }
  }


  private void saveSketch() {//現在開いているスケッチを自動保存
    frame.setTitle("スケッチ保存中");
    try {
      Savepath=Savepath+year()+month()+day()+"_"+hour()+minute()+second()+".dsd";//ファイル名に日付と時間を追加
      String path=Savepath;
      println(path);

      ObjectOutputStream os=new ObjectOutputStream(new FileOutputStream(new File(path)));
      println("保存-path"+path);

      //ファイルにオブジェクトを書き込む
      os.writeObject(img.width);
      os.writeObject(img.height);
      img.loadPixels();
      os.writeObject(img.pixels);
      os.writeObject(depthMap);
      os.writeObject(realWorldMap_back);

      int i=0;
      for (DT line : lines) {
        if (line.getSaveMode()==-1)continue;
        i++;
      }
      os.writeObject(i);
      println("iの値を表示"+i);
      i=0;
      for (DT line : lines) {
        //タイプ(line or spray)//
        int n=line.getSaveMode();
        if (n==-1)continue;
        os.writeObject(n);
        //タイプ//
        os.writeObject(line.getColor());//色
        os.writeObject(line.getWeight());//太さ
        ArrayList<PVector>l=new ArrayList<PVector>();
        l.addAll(line);
        os.writeObject(l);//線データ
        i++;
      }
      println("iの値を表示"+i);
      os.close();//使い終わったら閉める

      //現在の画面も保存する
      saveFrame(path+".png");
    }
    catch(Exception e) {
      System.err.println("書き込みに失敗しました。");
      e.printStackTrace();
    }
  }


  PVector calcRealPoint(float z, float x, float y) {//移動量0の時のみZ距離を計算できる関数
    float mag=2*z/LENGTH;
    x=(x-img.width/2)*mag;
    y=(img.height/2-y)*mag;
    return new PVector(x, y, z);
  }

  public float myScreenZ(float x, float y, float z) {//スクリーンからのZ教理を求めようとしてみたやつ。うまくいってない。
    float xx, yy, zz;
    x+=pos.x;
    y+=pos.y;
    z+=pos.z;
    z+=-1000;
    x*=0.575f*width/img.width;
    y*=0.575f*width/img.width;
    z*=0.575f*width/img.width;
    xx=x*cos(rotY)-z*sin(rotY);
    zz=x*sin(rotY)+z*cos(rotY);
    x=xx;
    z=zz;
    yy=y*cos(rotX)-z*sin(rotX);
    zz=y*sin(rotX)+z*cos(rotX);
    z=zz;
    return -z+1200-150;
  }
}

boolean isCross(PVector s1, PVector v1, PVector s2, PVector v2) {//始点s,方向vの線分と線分が交差しているか
  float cross=get_cross(v1, v2);
  if (cross==0)return false;
  PVector v=new PVector(s2.x-s1.x, s2.y-s1.y);
  float t1=get_cross(v, v1)/cross;
  float t2=get_cross(v, v2)/cross;
  return 0<=t1&&t1<=1&&0<=t2&&t2<=1;
}

float get_cross(PVector p1, PVector p2) {//外積を取得
  return p1.x*p2.y-p2.x*p1.y;
}

public static FilenameFilter getFileExtensionFilter(String extension) {//拡張子 extension で filterするためのクラス。
  final String _extension = extension;  
  return new FilenameFilter() {  
    public boolean accept(File file, String name) {  
      boolean ret = name.endsWith(_extension);   
      return ret;
    }
  };
}

