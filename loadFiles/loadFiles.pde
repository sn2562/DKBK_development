//processing-java --run --force --sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --output=sketch=/Users/kawasemi/Documents/processing2014/DKBK_development/loadFiles --force

FileList p;
String path = "/Users/kawasemi/Desktop/dsd";//データが格納されているフォルダのパス

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
			if(m != null){//検索結果あり
				println(fileArray[i]);
				//TODO : サムネイルを表示する
				PImage img;
				img = loadImage(path+"/"+fileArray[i]);
				image(img, 0, 0);
				
			}else{//不一致

			}
		}
	} else{
		println("この階層には何もありません");
	}
}