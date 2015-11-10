//processing-java --run --force --sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/UseShot --output=sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/UseShot/output --force

//二画面用
private PFrame data_frame;
private SecondApplet second_app;

boolean MainFrame = true;//二画面のうちどちらにいるか
int SecondAppletW=200;
int SecondAppletH=600;
ArrayList <ImButton> thumbnailButton = new ArrayList<ImButton>();//サムネイルボタン

//更新のじどうか
import SimpleOpenNI.*;
//changed 20150906z

String FilePath1;//始めにロードするデータとLキー押した時に読むデータのパスを入れ解くためのやつ(debug用)
boolean debugMode=false;//デバックモードがtrue時は自動的に上記のファイルをロードする。

final int K=2;//深度データ描写の細かさ
final int LENGTH=1145;//デプスデータを格納している配列の大きさ
final int data_width=640;//画像の解像度
final int data_height=480;//画像の解像度

final float screenZoom=1.2;//1.8;//描画範囲の倍率//1.5普段使い//1.2//微調整用

private TakeShot take;//データの保存に利用
private Tool tool;//ツールバー
private boolean pmousePressed;

static ArrayList<Data> data;//扱っているデータを格納しておく場所

static int setLineW;//線の太さ
static int animFrame;//フレームレートに沿ったフレーム数
static int frameset;//
static boolean animation;//アニメーションしてもいいかどうか
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

	println("aaa");
	println("ccc");

	oldToolNumber=0;
	context = new SimpleOpenNI(this);//カメラ更新用
	context.setMirror(false);//鏡では表示しない

	println("vvv");
	frame.setTitle("DKBK");
	size(int(640*screenZoom), int(480*screenZoom), P3D);

	//線の太さ、初期設定は3
	setLineW=7;

	FilePath1=dataPath("")+"/todai_horiken7.dsd";

	println("aaa");
	tool=new Tool();//ツールバー
	println("bbb");

	take=new TakeShot(this);//テイクショット

	//初期データの読み込み
	data=new ArrayList<Data>();
	if (debugMode)
		data.add(new Data(FilePath1));//デバック用のデータ読み込み
	else
		data.add(new Data(true));//空のデータを入れておく

	//表示について
	perspective(PI/4, float(width)/float(height), 10, 150000);//視野角は45度
	float z0 = (height/2)/tan(PI/8);//tan(radian(45/2))を使うと、微妙に数字がズレるのでダメ
	//カメラの位置を決める
	camera(width/2, height/2, z0, width/2, height/2, 0, 0, 1, 0);

	pmousePressed=false;



	//データ画面
	second_app = new SecondApplet();
	data_frame = new PFrame(second_app);
	data_frame.setTitle("data");
	data_frame.setLocation(1200, 200);

}

void draw() {
	frame.setTitle(data.get(tool.nowDataNumber).dataname+" "+round(frameRate));//
	//フレームの計算
	if (tool.animMode()) {
		//アニメーション用フレームレート
		animFrame++;
		frameset=(animFrame-1)/framecount;
		//表示するデータ番号を出力

		//tool.nowDataNumberを変更する
		tool.nowDataNumber=frameset%data.size();
		//println(frameset+":"+tool.moveWriter);

		//表示するデータを変更する draw_modeは0~3
		for (int i=0; i<data.size (); i++) {
			if (i==tool.nowDataNumber)//選択中のデータならば
				data.get(i).draw_mode=1;//0番の表示方法にあわせて表示
			else//それ以外
				data.get(i).draw_mode=3;//非表示
		}
	}

	tool.update();//ツールバーを更新

	background(252, 251, 246);//キャンバス背景色
	if (!tool.isDragged&&!tool.isDragged2)//ツールバーに重なってないのなら
		data.get(tool.nowDataNumber).draw();//線を描く

	if (tool.getMode()) {//trueでUseShotMode,falseでTakeShotMode
		context.update();//カメラ更新用
		//data内のデータを書き換える
		// data.get(tool.nowDataNumber).cameraChangeUpdate();
		//todo
		//useshot系データの描画
		for (int i=0; i<data.size (); i++) {//各種データの操作と描画
			data.get(i).update();

			if (tool.getMovMode()) {//trueで静止画モード,falseで動画モード
			} else {
				take.draw();
				take.save();//更新する
			}
		}
	} else {//takeshot
		take.draw();
	}

	tool.draw();//ツールバーを描画

	if(MainFrame)
		pmousePressed=mousePressed;//これをしておくことでマウスが一度だけ押されたのを取得する
}

void mousePressed() {
	//検証用
	//  println(tool.nowToolNumber);

	//切り替え

	//線の太さをペンのボタンで変更する
	setLineW=13;//それ以外は細く

	if (tool.getMode()) {
		if (!tool.pointOver(mouseX, mouseY)) {//ツールバーに重なってないのなら
			data.get(tool.nowDataNumber).addLine();//線を追加
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
	//回転操作をリセットする
	if ( mouseButton == RIGHT ) {
		if (!tool.moveWriter)
			data.get(tool.nowDataNumber).matrixReset();
		else
			tool.matrixReset();
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
		setLineW=12;//それ以外は細く

	if ( mouseButton == RIGHT ) {//右クリックをしていたら
		//閲覧操作
		//回転か並行かを判定する
		if (!tool.moveMode) {
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
	} else {//それ以外
		//ツールごとの設定
		if (tool.getMode()) {
			if (!tool.isDragged&&!tool.isDragged2)//ツールバーに重なってないのなら
				switch(tool.nowToolNumber) {
				case 0://補正ペン
				//println("tool.nowToolNumberを表示"+tool.nowToolNumber);
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
				//移動量を出力
				data.get(tool.nowDataNumber).printTR();
				//検証用2
				if (keyEvent==null) {//起動直後
					//回転か並行かを判定する
					if (!tool.moveMode) {
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
				} else if (keyEvent.isShiftDown()||!tool.moveMode) {
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
				break;
			}
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
				data.add(new Data(FilePath1));
			break;
			case 'P'://データをpcdとして書き出す
			println("make pcd data");
			printPCD();
			//data.get(tool.nowDataNumber).saveJsonData();
			data.get(tool.nowDataNumber).saveJsonArrayData();

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

public void printPCD() {
	println("printPCD");
	StringList l = new StringList();
	int linenum=0;
	//pcl用のヘッダを追加
	l.append("VERSION .7");
	l.append("FIELDS x y z rgb");
	l.append("SIZE 4 4 4 4");
	l.append("TYPE F F F F");
	l.append("COUNT 1 1 1 1");
	/*
       l.append("WIDTH "+str(data_width/2));
   l.append("HEIGHT "+str(data_height/2));
   */
	l.append("WIDTH 1");
	l.append("HEIGHT 1");
	l.append("VIEWPOINT 0 0 0 1 0 0 0");
	l.append("POINTS 0");
	l.append("DATA ascii");

	//realWorldPointの中身をすべて出力
	int W=data.get(tool.nowDataNumber).getW();//データの幅
	int H=data.get(tool.nowDataNumber).getH();//データの高さ
	for (int y=0; y < H; y+=3) {//3ずつ読み込み
		for (int x=0; x < W; x+=3) {//3ずつ読み込み
			int index = x + y * W;//インデックスを計算する
			PVector realWorldPoint = data.get(tool.nowDataNumber).getVector(index);//realWorldMap_backのindexの値を取得する
			if (realWorldPoint.z > 0) {//もしポイントのｚの値が0以上なら
				linenum++;//linenumを1増やす
				l.append(str(realWorldPoint.x)+" "+str(realWorldPoint.y)+" "+str(realWorldPoint.z)+" "+"4.2108e+06");//値のx座標,y座標,z座標,色情報を書き込む
			}
		}
	}

	for (int i=linenum; linenum!=data_width*data_height/4; linenum++) {
		l.append("");
	}
	l.set(5, "WIDTH "+linenum);//5行目に行数を書く
	l.set(8, "POINTS "+linenum);//8行目にポイント数の合計を書く

	saveStrings("data/PointCroudData.pcd", l.array());//pcdデータの書き出し
	saveStrings("data/PointCroudData.txt", l.array());//txtデータの書き出し(確認用)
	println("end : printPCD");
	return;
}
void mouseMoved() {//チェック
	MainFrame=true;
}

//サムネイルの追加
void addThumbnail(PImage g){
	//TODO : closeの時は追加しない
	if (thumbnailButton.size()==1&&tool.nowDataNumber==0){

	};
	println("ボタンを追加");
	PImage p;
	try {
		p = (PImage)g.clone();  // データの実体のコピー
		p.resize(0,100);//画像のリサイズ
		thumbnailButton.add(new ImButton(p, (SecondAppletW-p.width)/2, thumbnailButton.size()*100));
	} catch (Exception e) {
		// 例外処理
	}
}


//データ画面
class SecondApplet extends PApplet {
	//サムネイル表示用
	String path = "/Users/kawasemi/Desktop/dsd";//データが格納されているフォルダのパス
	FileList p;//フォルダの中身一覧
	int imgNum = 0;//画像数
	float scrollY=0;//スクロール量

	void setup() {
		size( SecondAppletW, SecondAppletH );
		p = new FileList(path);
		println("p "+p.getFileList().length);
		//		console(p.getFileList());
	}

	void draw() {
		background(255);
		fill(255, 0, 0);
		ellipse( mouseX, mouseY, 50, 50 );

		//各種ボタン描画
		//ホイール位置に合わせて描画位置を移動
		pushMatrix();
		translate(0,scrollY);
		for (int i=0; i<thumbnailButton.size(); i++){
			//			thumbnailButton[i].draw(mouseX-getX(), mouseY-getY());
			rect(thumbnailButton.get(i).getX(), thumbnailButton.get(i).getY(), thumbnailButton.get(i).getW(), thumbnailButton.get(i).getH());//ここの描画先を変更したい
			image(thumbnailButton.get(i).getImg(), thumbnailButton.get(i).getX(), thumbnailButton.get(i).getY(), thumbnailButton.get(i).getW(), thumbnailButton.get(i).getH());
		}
		popMatrix();

		update();

		if(!MainFrame)
			pmousePressed=mousePressed;//これをしておくことでマウスが一度だけ押されたのを取得する


	}

	void console(String[] fileArray){
		if (fileArray != null) {
			//画像の枚数をカウントする
			for(int i = 0; i < fileArray.length; i++) {
				if(match(fileArray[i], ".png") != null)
					imgNum++;
				//TODO : nullだった時(画像じゃない時)はその要素を配列から消しておきたい 
			}
			//画像付きボタンを作成する
			//			thumbnailButton = new ImButton[imgNum];

			imgNum=0;
			//画像だった時にサムネイルを作成する
			PImage g;

			//イカの部分を追加される度に実行する部分にすればいい...
			for(int i = 0; i < fileArray.length; i++) {//二度目
				if(match(fileArray[i], ".png") != null){
					//画像付きボタンを作成する
					g=loadImage(path+"/"+fileArray[i]);//画像の読み込み
					g.resize(0,100);//画像のリサイズ
					thumbnailButton.add(new ImButton(g, (width-g.width)/2, imgNum*100));
					imgNum++;
				}
			}
		} else{
			println("この階層には何もありません");
		}
	}

	public void update() {//毎秒呼び出して画像がクリックされているかどうかをチェックする
		//各種ボタンが押された時の処理
		for (int i=0; i<thumbnailButton.size(); i++) {
			if(MainFrame)//この画面じゃないならやらない
				break;
			thumbnailButton.get(i).update(mouseX-getX(), mouseY-getY()-scrollY);
			if (thumbnailButton.get(i).isMouseOver&& !pmousePressed&&mousePressed) {
				thumbnailButton.get(i).setSelected(false);
				println(i+" : 押されました");

				//TODO : ツール番号を変更する
								tool.nowDataNumber=i;
			}
		}
	}

	//マウスホイールによって画面をスクロールする
	void mouseWheel(MouseEvent event) {
		float e = event.getCount();
		scrollY=scrollY+e;
	}

	void mouseMoved() {//チェック
		MainFrame=false;
	}

	boolean buttonMouseOver (){
		return true;
	}
}