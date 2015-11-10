import java.awt.Frame;
import java.awt.Insets;

public class PFrame extends Frame {  
	public PFrame(PApplet app) {
		app.init();
		while ( app.width<=PApplet.DEFAULT_WIDTH || app.height<=PApplet.DEFAULT_HEIGHT );
		Insets insets = frame.getInsets();
		setSize( app.width + insets.left + insets.right, app.height + insets.top + insets.bottom );
		setResizable(false);    
		add(app);
		show();
	}
}
