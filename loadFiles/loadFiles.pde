//processing-java --run --force --sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --output=sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --force

FileList p;
String path = "/Users/kawasemi/Desktop/dsd";//データが格納されているフォルダのパス
int imgNum = 0;
boolean pmousePressed=false;
//boolean loaded=false;


//画像をボタン化したい
ImButton[] thumbnailButton;

void setup(){
	size(500,500);
	p = new FileList(path);
	println("p "+p.getFileList().length);
	console(p.getFileList());
}
void draw(){
	//各種ボタン描画
	//	if(loaded){
	for (int i=0; i<thumbnailButton.length; i++){
		thumbnailButton[i].draw(mouseX-getX(), mouseY-getY());
	}

	//	thumbnailButton[i].draw(mouseX-getX(), mouseY-getY());

	update();	
	//	}

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
				//				thumbnailButton[imgNum].draw(mouseX, mouseY);
				imgNum++;
			}
		}
		//		loaded = true;
	} else{
		println("この階層には何もありません");
	}
}

public void update() {//毎秒呼び出して画像がクリックされているかどうかをチェックする
	//各種ボタンが押された時の処理
	noLoop();
}