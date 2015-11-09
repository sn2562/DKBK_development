import java.io.*;
public class FileList {
	public FileList() {
		File directory1 = new File("/Users/kawasemi/Desktop");
		String[] fileArray = directory1.list();
		if (fileArray != null) {
			for(int i = 0; i < fileArray.length; i++) {
				System.out.println(fileArray[i]);
			}
		} else{
			System.out.println(directory1.toString() + "　は存在しません" );
		}
	}
}
