//processing-java --run --force --sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/someWindow --output=sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/someWindow/output

//二画面用
PFrame second_frame;
SecondApplet second_app;
boolean MainFrame = true;//二画面のうちどちらにいるか

//サムネイル表示用
String path = "/Users/kawasemi/Desktop/dsd";//データが格納されているフォルダのパス
FileList p;//フォルダの中身一覧
ImButton[] thumbnailButton;//サムネイルボタン
int imgNum = 0;//画像数
float scrollY=0;//スクロール量


boolean pmousePressed=false;

void setup() {
	size(400, 300);

	second_app = new SecondApplet();
	second_frame = new PFrame(second_app);//second_app関数を呼ぶ

	second_frame.setTitle("2nd frame");
	second_frame.setLocation(1200, 200);
}

void draw() {
	//reset
	background(150);
	fill(0, 255, 0);
	ellipse( mouseX, mouseY, 100, 100 );
}

void mouseMoved() {//チェック
	MainFrame=true;
}

class SecondApplet extends PApplet {
	void setup() {
		size( 200, 600 );
		p = new FileList(path);
		println("p "+p.getFileList().length);
		console(p.getFileList());
	}

	void draw() {
		background(255);
		fill(255, 0, 0);
		ellipse( mouseX, mouseY, 50, 50 );


		//各種ボタン描画
		//ホイール位置に合わせて描画位置を移動
		pushMatrix();
		translate(0,scrollY);
		for (int i=0; i<thumbnailButton.length; i++){
			//			thumbnailButton[i].draw(mouseX-getX(), mouseY-getY());
			rect(thumbnailButton[i].getX(), thumbnailButton[i].getY(), thumbnailButton[i].getW(), thumbnailButton[i].getH());//ここの描画先を変更したい
			image(thumbnailButton[i].getImg(), thumbnailButton[i].getX(), thumbnailButton[i].getY(), thumbnailButton[i].getW(), thumbnailButton[i].getH());
		}
		popMatrix();

		update();
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
			thumbnailButton = new ImButton[imgNum];

			imgNum=0;
			//画像だった時にサムネイルを作成する
			PImage g;
			for(int i = 0; i < fileArray.length; i++) {//二度目
				if(match(fileArray[i], ".png") != null){
					//画像付きボタンを作成する
					g=loadImage(path+"/"+fileArray[i]);//画像の読み込み
					g.resize(0,100);//画像のリサイズ
					thumbnailButton[imgNum]=new ImButton(g, (width-g.width)/2, imgNum*100);
					imgNum++;
				}
			}
		} else{
			println("この階層には何もありません");
		}
	}

	public void update() {//毎秒呼び出して画像がクリックされているかどうかをチェックする
		//各種ボタンが押された時の処理
		for (int i=0; i<thumbnailButton.length; i++) {
			if(MainFrame)//この画面じゃないならやらない
				break;
			thumbnailButton[i].update(mouseX-getX(), mouseY-getY()-scrollY);
			if (thumbnailButton[i].isMouseOver&& !pmousePressed&&mousePressed) {
				thumbnailButton[i].setSelected(false);
				println(i+" : 押されました");
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