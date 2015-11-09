//processing-java --run --force --sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --output=sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --force

FileList p;
String path = "/Users/kawasemi/Desktop/dsd";//データが格納されているフォルダのパス
int imgNum = 0;

void setup(){
	size(500,500);
	p = new FileList(path);
	println("p "+p.getFileList().length);
	console(p.getFileList());

	noLoop();
}
void draw(){
}

void console(String[] fileArray){
	if (fileArray != null) {
		for(int i = 0; i < fileArray.length; i++) {
			String[] m = match(fileArray[i], ".png");
			if(m != null){//もし画像ならば
				//println(fileArray[i]);
				//TODO : サムネイルを表示する
				PImage img;
				img = loadImage(path+"/"+fileArray[i]);
				img.resize(0,100);
				//				image(img, 0, imgNum*100, img.width/4, img.height/4);
				image(img, (width-img.width)/2, imgNum*100);
				imgNum++;
			}else{//不一致

				
			}
		}
	} else{
		println("この階層には何もありません");
	}
}