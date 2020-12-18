import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.HashSet;
import java.util.Set;
import java.util.Comparator;
import java.util.ListIterator;

import org.chocosolver.solver.Model;
import org.chocosolver.solver.variables.IntVar;

import processing.sound.*;
processing.sound.Sound s;

int[][]  board = new int[9][9];


SoundFile backgroundMusic;
GridLayout gridLayout;



void setup() {
	size(800, 600);
	frameRate(30);
	
	surface.setResizable(true);

	
	gridLayout = new GridLayout(this,12,12, 10);
	
	Button resetButton = new Button("Reset");
	resetButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			reset();
		}
	} );
	gridLayout.addGridElement(resetButton, 0,1,3,1);
	
	Button loadButton = new Button("Load...");
	loadButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			selectInput("Import Sudoku file", "importSudoku");
		}
	} );
	gridLayout.addGridElement(loadButton, 0,2,3,1);
	
	Button saveButton = new Button("Save...");
	saveButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			selectOutput("Export Sudoku file", "exportSudoku");
		}
	} );
	gridLayout.addGridElement(saveButton, 0,3,3,1);
	
	SelectBox selectBox = new SelectBox("Solver", new String[]{"Backtrack", "Constraint"} );
	gridLayout.addGridElement(selectBox, 0,4,3,1);
	


	final ImageButton playButton = new ImageButton("play-circle");
	playButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			if(playButton.getIconName().equals("play-circle")){
				playButton.setIcon("pause-circle");
				backgroundMusic.play();
			} else {
				playButton.setIcon("play-circle");
				backgroundMusic.pause();
			}
			
		}
	} );
	gridLayout.addGridElement(playButton, 0, 10, 1, 1);

	Slider volumeSlider = new Slider(300,100, 0,10,5);
	volumeSlider.setOnSliderChangeListener(new OnSliderChangeListener(){
		@Override
		public void onSliderChange(int value){
			backgroundMusic.amp(value/10.0f);
		}
	});
	gridLayout.addGridElement(volumeSlider, 1, 10, 2, 1);

	final SudokuWidget sudoku = new SudokuWidget(board);
	gridLayout.addGridElement(sudoku, 4,1,8,9);

	Button backButton = new ImageButton("arrow-alt-circle-left");
	backButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			sudoku.revertLastMove();
		}
	} );
	gridLayout.addGridElement(backButton, 4, 10,1,1);

	Button nextButton = new ImageButton("arrow-alt-circle-right");
	nextButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			sudoku.redoLastMove();
		}
	} );
	gridLayout.addGridElement(nextButton, 5, 10,1,1);

	Button solveButton = new Button("Solve");
	solveButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			
			long startTime = System.nanoTime();
			solve();
			long endTime = System.nanoTime();
			
			long duration = (endTime - startTime) / 1000000;  //divide by 1000000 to get milliseconds.
			
			println("took " + duration + "ms");
			
		}
	} );
	gridLayout.addGridElement(solveButton, 6,10,2,1);

	Button hintButton = new Button("Hint");
	hintButton.setOnClickPressedListener(new OnClickPressedListener() {
		@Override
		public void onClickPressed(int x, int y) {
			
			//TODO
			
		}
	} );
	gridLayout.addGridElement(hintButton, 8,10,2,1);

	
	backgroundMusic = new SoundFile(this, "sounds/gui/out2.wav");
	backgroundMusic.amp(0.5f);	
}

void reset() {
	
	for (int i = 0; i < 9; i++) {
		for (int j = 0; j < 9; j++) {
			board[i][j] = 0;
			//boardOrg[i][j] = 0;
		}
	}
	
}

void exportSudoku(File selection) {
	if (selection == null) {
		println("Window was closed or the user hit cancel.");
		return;
	}
	println("User selected " + selection.getAbsolutePath());
	PrintWriter output  = createWriter(selection.getAbsolutePath());
	for (int i = 0; i < 9; i++) {
		for (int j = 0; j < 9; j++) {
			output.print(board[i][j] == 0 ? '.' : Character.forDigit(board[i][j],10));
		}
	}
	output.println();
	output.flush(); 
	output.close();
}


void importSudoku(File selection) {
	if (selection == null) {
		println("Window was closed or the user hit cancel.");
		return;
	}
	println("User selected " + selection.getAbsolutePath());
	
	
	// import file
	String[] lines = loadStrings(selection.getAbsolutePath());
	for (String line : lines) {
		if (line.length() == 81) {
			for (int i = 0; i < 81; i++) {
				int indexX = i % 9;
				int indexY = floor(i / 9);
				char c = line.charAt(i);
				if (c == '.') {
					board[indexY][indexX] = 0;
				} else {
					board[indexY][indexX] = Character.getNumericValue(c);
				}
			}
			return;
		}
	}
}





void solve() {
	
	
	// if (!checkValid()) {
	// 	println("not valid!");
	// 	return;
	// }
	// while(solve_crme()) {};
	//solve_backtrack();
	
	
	
	Model model = new Model("Sudoku solver");
	int n = 9;
	
	IntVar[][] rows = new IntVar[n][n];
	IntVar[][] cols = new IntVar[n][n];
	IntVar[][] carres = new IntVar[n][n];
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < n; j++) {
			if (board[i][j] > 0) {
				rows[i][j] = model.intVar(board[i][j]);
			} else {
				rows[i][j] = model.intVar("c_" + i + "_" + j, 1, n, false);
			}
			cols[j][i] = rows[i][j];
		}
	}
	
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			for (int k = 0; k < 3; k++) {
				carres[j + k * 3][i] = rows[k * 3][i + j * 3];
				carres[j + k * 3][i + 3] = rows[1 + k * 3][i + j * 3];
				carres[j + k * 3][i + 6] = rows[2 + k * 3][i + j * 3];
			}
		}
	}
	
	for (int i = 0; i < n; i++) {
		model.allDifferent(rows[i], "AC").post();
		model.allDifferent(cols[i], "AC").post();
		model.allDifferent(carres[i], "AC").post();
	}
	
	model.getSolver().solve();
	
	
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < n; j++) {
			board[i][j] = rows[i][j].getValue();
		}
	}
	
}


void keyTyped() {

	if (key == 's') {
		solve();
		return;
	}

}


void draw() {
	background(200, 200, 255);
}




public boolean checkValid() {
	for (int y = 0; y < 9; y++) {
		for (int x = 0; x < 9; x++) {
			if (board[y][x] != 0) {
				int val = board[y][x];
				board[y][x] = 0;
				boolean valid = isValid(y,x,val);
				board[y][x] = val;
				if (!valid) {
					return false;
				}
			}
		}
	}
	return true;
}

public boolean isValid(int x, int col, int num) {
	//check y
	for (int c = 0; c < 9; c++) {
		if (board[x][c] == num) {
			return false;
		}
	}
	
	//check x
	for (int r = 0; r < 9; r++) {
		if (board[r][col] == num) {
			return false;
		}
	}
	
	//check minigrid
	int startCol = col - (col % 3);
	int startRow = x - (x % 3);
	for (int r = 0; r < 3; r++) {
		for (int c = 0; c < 3; c++) {
			if (board[r + startRow][c + startCol] == num) {
				return false;
			}
		}
	}
	
	return true;
}


public boolean solve_backtrack()
{
	int x = - 1;
	int col = - 1;
	boolean isEmpty = true;
	for (int i = 0; i < 9; i++) 
	{
		for (int j = 0; j < 9; j++) 
		{
			if (board[i][j] == 0) 
			{
				x = i;
				col = j;
				
				// We still have some remaining
				// missing values in Sudoku
				isEmpty = false;
				break;
			}
		}
		if (!isEmpty) {
			break;
		}
	}
	
	// No empty space left
	if (isEmpty) 
	{
		return true;
	}
	
	// Else for each-x backtrack
	for (int num = 1; num <= 9; num++) 
	{
		if (isValid(x, col, num)) 
		{
			board[x][col] = num;
			if (solve_backtrack()) 
			{
				return true;
			}
			else
			{
				// replace it
				board[x][col] = 0;
			}
		}
	}
	return false;
}




public interface OnClickPressedListener {
	void onClickPressed(int x, int y);
}

public interface OnClickReleasedListener {
	void onClickReleased(int x, int y);
}

public interface OnMouseEnterListener {
	void onMouseEnter(int x, int y);
}

public interface OnMouseLeaveListener {
	void onMouseLeave(int x, int y);
}

public interface OnMouseMoveListener {
	void onMouseMove(int x, int y);
}

public interface OnKeyTypedListener {
	void onKeyTyped(char key);
}

public interface OnSliderChangeListener {
	void onSliderChange(int value);
}


public class Move {
	Coordinate coordinate;
	int valueBefore;
	int valueAfter;
	public Move(Coordinate coordinate, int valueBefore, int valueAfter){
		this.coordinate = coordinate;
		this.valueBefore = valueBefore;
		this.valueAfter = valueAfter;
	}

	public Coordinate getCoordinate(){
		return coordinate;
	}

	public int getValueBefore(){
		return valueBefore;
	}

	public int getValueAfter(){
		return valueAfter;
	}

}

public class Coordinate {
	private int x;
	private int y;
	public Coordinate(int x, int y){
		this.x = x;
		this.y = y;
	}
	int getX(){
		return this.x;
	}
	int getY() {
		return this.y;
	}
	void setX(int x){
		this.x = x;
	}
	void setY(int y){
		this.y = y;
	}
	void setXY(int x, int y){
		this.x = x;
		this.y = y;
	}
}

public class SudokuWidget extends WidgetBase {
	

	int[][] board;
	int[][] boardOriginal;
	List<Move> moves = new ArrayList<Move>();
	int moveIndex = -1;
	int blinkTime;
	boolean blinkOn;
	Coordinate selectedCoordinate = new Coordinate(-1,-1);
	Coordinate hoveredCoordinate = new Coordinate(-1,-1);

	int lastX;
	int lastY;
	float cellSize;

	public SudokuWidget(int[][] board){
		this.board = board;
		this.boardOriginal = new int[board.length][board[0].length];
		cloneArray(board, boardOriginal);
	}


	public void revertLastMove(){
		if(moveIndex >= 0){
			Move lastMove = moves.get(moveIndex);
			Coordinate coordinate = lastMove.getCoordinate();
			board[coordinate.getY()][coordinate.getX()] = lastMove.getValueBefore();
			moveIndex--;
		}
	}

	public void redoLastMove(){
		if(moveIndex < moves.size() - 1){
			moveIndex++;
			Move lastMove = moves.get(moveIndex);
			Coordinate coordinate = lastMove.getCoordinate();
			board[coordinate.getY()][coordinate.getX()] = lastMove.getValueAfter();
		}
	}

	private void cloneArray(int[][] src, int[][] dst) {
	for (int i = 0; i < src.length; i++) {
		for (int j = 0; j < src[i].length; j++) {	
			dst[i][j] = src[i][j];
		}
	}
}

	@Override
	public void onMouseEnter(int x, int y){}
	
	@Override
	public void onMouseLeave(int x, int y){
		hoveredCoordinate.setXY(-1, -1);
	}
	
	@Override
	public void onMouseMove(int x, int y){
		int xIndex = floor((x - lastX) / cellSize);
		int yIndex = floor((y - lastY) / cellSize);
		if (xIndex < 0 || yIndex < 0 || xIndex > 8 || yIndex > 8 || boardOriginal[yIndex][xIndex] != 0) {
			hoveredCoordinate.setXY(-1, -1);
			return;
		}
		hoveredCoordinate.setXY(xIndex, yIndex);
	}
	
	@Override
	public void onClickPressed(int x, int y){
		int xIndex = floor((x - lastX) / cellSize);
		int yIndex = floor((y - lastY) / cellSize);
		
		if (xIndex < 0 || yIndex < 0 || xIndex > 8 || yIndex > 8 || boardOriginal[yIndex][xIndex] != 0) {
			selectedCoordinate.setXY(-1, -1);
			return;
		}
		selectedCoordinate.setXY(xIndex, yIndex);
		blinkTime = millis();
		blinkOn = true;
	}
	
	@Override
	public void onClickReleased(int x, int y){}

	@Override
	public void onKeyTyped(char key){

		if (selectedCoordinate.getX() == - 1) {
			return;
		}
		
		if (key == BACKSPACE) {
			int oldVal = board[selectedCoordinate.getY()][selectedCoordinate.getX()];
			if(oldVal == 0){
				return;
			}
			while(moveIndex < moves.size()-1){
				moves.remove(moves.size()-1);
			}
			moves.add(new Move(new Coordinate(selectedCoordinate.getX(), selectedCoordinate.getY()), oldVal, 0));

			moveIndex++;
			board[selectedCoordinate.getY()][selectedCoordinate.getX()] = 0;
			selectedCoordinate.setXY(-1,-1);
			return;
		}
		
		if (key < '1' || key > '9') {
			return;
		}
		int val = Character.getNumericValue(key);
		int oldVal = board[selectedCoordinate.getY()][selectedCoordinate.getX()];
		if(val == oldVal){
			return;
		}
		while(moveIndex < moves.size()-1){
				moves.remove(moves.size()-1);
		}
		moves.add(new Move(new Coordinate(selectedCoordinate.getX(), selectedCoordinate.getY()), oldVal, val));
		moveIndex++;
		board[selectedCoordinate.getY()][selectedCoordinate.getX()] = val;
		selectedCoordinate.setXY(-1,-1);

	}

	@Override
	public void draw(int _x, int _y, int width, int height) {
		// noFill();
		// rect(_x,_y,width,height);
		lastX = _x;
		lastY = _y;
		cellSize = min(width, height) / 9f;

		for (int i = 0; i < 9; i++) {
			for (int j = 0; j < 9; j++) {
				
				float x = _x + i * cellSize;
				float y = _y + j * cellSize;
				stroke(150);
				int alpha = 180;
				// hover gray
				if (i == hoveredCoordinate.getX() && j == hoveredCoordinate.getY()) {
					fill(160,160,160,alpha); 
				} 
				// normal white
				else {
					fill(255,255,255,alpha);
				}
				
				// draw cells
				rect(x, y, cellSize, cellSize);
				
				// selected cell - blinking cursor
				if (boardOriginal[j][i] == 0 && i == selectedCoordinate.getX() && j == selectedCoordinate.getY()) {
					if (blinkOn) {
						fill(220,220,220, 150);
						stroke(0);
						line(x + cellSize * 0.2,y  + cellSize * 0.95,x  + cellSize * 0.8, y  + cellSize * 0.95);
					}
					
					if (millis() - 500 > blinkTime) {
						blinkTime = millis();
						blinkOn = !blinkOn;
						
					}
				}
				
				// draw number
				if (board[j][i] != 0) {
					textSize(cellSize * 0.8);
					textAlign(CENTER,CENTER);
					
					// user number is red
					if (boardOriginal[j][i] == 0) {
						fill(100,0,0);
					} else {
						fill(50);
					}
					text("" + board[j][i],x  + cellSize / 2,y + cellSize / 2); 
				}
			}
		}
		noFill();
		stroke(0);
		strokeWeight(1.2);
		for (int i = 0; i < 3; i++) {
			for (int j = 0; j < 3; j++) {
				float x = _x + i * cellSize * 3;
				float y = _y + j * cellSize * 3;
				rect(x , y , cellSize * 3, cellSize * 3);
			}
		}
		strokeWeight(1);
	}

}

public class SelectBox extends WidgetBase {
	
	String text;
	String[] options;
	int selectedOption = 0;
	
	private boolean[] hovered;
	private boolean clicked;
		
	int lastX;
	int lastY;
	int lastWidth;
	int lastHeight;
	
	public SelectBox(String text, String[] options) {
		super(3, 1);
		this.hovered = new boolean[options.length + 1];
		this.clicked = false;
		this.text = text;
		this.options = options;
	}

	@Override
	public void onMouseEnter(int x, int y) {}
	
	@Override
	public void onMouseLeave(int x, int y) {
		Arrays.fill(hovered, false);
		clicked = false;
	}
	
	@Override
	public void onMouseMove(int x, int y) {
		Arrays.fill(hovered, false);
		int index = (y - lastY) / lastHeight;
		hovered[index] = true;
		
	}
	
	@Override
	public void onClickPressed(int x, int y) {
		hasOverlay = !hasOverlay;
		int index = (y - lastY) / lastHeight;
		if (index == 0) {
			clicked = true;
		} else {
			selectedOption = index - 1;
		}
		
	}
	
	@Override
	public void onClickReleased(int x, int y) {
		clicked = false;
	}

	@Override
	public void onKeyTyped(char key){}	

	@Override
	public void draw(int x, int y, int width, int height) {
		lastX = x;
		lastY = y;
		lastWidth = width;
		lastHeight = height;
		overlayHeight = height * options.length;
		
		int heightBase = height;
		int col = clicked ? 150 : hovered[0] ? 100 : 50;
		//int alpha = 220;
		stroke(col);
		fill(col);
		rect(x,y,width,heightBase);
		fill(255);
		textAlign(RIGHT, CENTER);
		textSize(min(width, heightBase) * 0.3);
		text(hasOverlay ? "▲" : "▼",x + width - 10,y + heightBase / 2);
		textAlign(CENTER, CENTER);
		text(text + " : " + options[selectedOption], x + width / 2, y + heightBase / 2);
		textSize(14);
		if (hasOverlay) {
			int offset = width / this.width / 2;
			for (int i = 0; i < options.length; i++) {
				noStroke();
				col = hovered[i + 1] ? 100 : 50;
				fill(col);
				rect(x + offset,y + heightBase * (i + 1),width - offset,heightBase);
				fill(255);
				textAlign(CENTER, CENTER);
				textSize(min(width, heightBase) * 0.3);
				text(options[i], x + width / 2, y + heightBase * (i + 1) + heightBase / 2);
				textSize(14);
			}
		}
	}
	
}


public class Slider extends WidgetBase {
	
	private int min;
	private int max;
	private int value;
	
	private boolean hovered = false;
	private boolean clicked = false;

	int lastWidth;
	int lastX;
	float lastHandleWidth;

	OnSliderChangeListener onSliderChangeListener;
	
	
	public Slider(int width, int height, int min, int max, int value) {
		super(width,height);
		this.min = min;
		this.max = max;
		this.value = value;
	}

	public void setOnSliderChangeListener(OnSliderChangeListener onSliderChangeListener){
		this.onSliderChangeListener = onSliderChangeListener;
	}
	
	@Override
	public void onMouseEnter(int x, int y) {
	}
	
	@Override
	public void onMouseLeave(int x, int y) {
		clicked=false;
	}
	
	@Override
	public void onMouseMove(int x, int y) {
		if(clicked){
			int segmentWidth = round(lastWidth/(float)(max-min+1));
			int offset =  x - lastX;
			int index = floor(offset/segmentWidth);
			int new_value =  min(max,min+index);
			if(value != new_value){
				value = new_value;
				if(onSliderChangeListener != null){
					onSliderChangeListener.onSliderChange(value);
				}
			}
		}
	}
	
	@Override
	public void onClickPressed(int x, int y) {
		clicked = true;
		float segmentWidth = lastWidth/(float)(max-min+1);
		int offset =  x - lastX;
		int index = floor(offset/segmentWidth);
		int new_value = min(max,min+index);
		if(value != new_value){
			value = new_value;
			if(onSliderChangeListener != null){
				onSliderChangeListener.onSliderChange(value);
			}
		}
	}
	
	@Override
	public void onClickReleased(int x, int y) {
		clicked = false;
	}	
	
	@Override
	public void onKeyTyped(char key){}

	@Override
	public void draw(int x, int y, int width, int height) {
		lastWidth = width;
		lastX = x;

		int lineHeight = round(height*0.1);
		float handleWidth = width / (float)(max-min+1);
		int handleHeight = lineHeight*3;

		lastHandleWidth = handleWidth;

		stroke(50);
		noFill();
		fill(50);
		rect(round(x+handleWidth*0.5),round(y+height/2-lineHeight/2),width-handleWidth,lineHeight, 10);

		
		stroke(40);
		fill(40);
		rect(x+value*handleWidth,round(y+height/2 - handleHeight/2),handleWidth,handleHeight, 7);
		textAlign(CENTER, CENTER);
		textSize(min(width, height) * 0.3);
		text("" + value, x + width/2, y + height/2 + handleHeight);
	}
	
}

public class ImageButton extends Button {
	PShape icon;
	String iconName;
	float ratio;

	public ImageButton(String iconName){
		super("");
		setIcon(iconName);
	}

	public void setIcon(String iconName){
		this.iconName = iconName;
		this.icon = loadShape("icons/"+iconName+".svg");
		this.icon.disableStyle();
		this.ratio = this.icon.getWidth()/(float)this.icon.getHeight();
	}

	public String getIconName(){
		return this.iconName;
	}

	@Override
	public void draw(int x, int y, int width, int height) {
		int iconHeight = round(min(width,height)*0.5);
		int iconWidth = round(iconHeight*ratio);
		int col = clicked ? 150 : hovered ? 100 : 50;
		//int alpha = 220;
		stroke(col);
		fill(col);
		rect(x,y,width,height, 10);

		fill(255);
		shape(icon, x + width / 2 - iconWidth/2, y + height / 2 - iconHeight/2, iconWidth, iconHeight);
	}
}

public class Button extends WidgetBase {
	
	String text;
	boolean hovered = false;
	boolean clicked = false;
	
	
	public Button(String text) {
		super(300, 100);
		this.text = text;
	}
	
	public Button(int width, int height, String text) {
		super(width, height);
		this.text = text;
	}

	public void setText(String text){
		this.text = text;
	}
	
	@Override
	public void onMouseEnter(int x, int y) {
		this.hovered = true;
	}
	
	@Override
	public void onMouseLeave(int x, int y) {
		this.hovered = false;
		this.clicked = false;
	}
	
	@Override
	public void onMouseMove(int x, int y) {
	}
	
	@Override
	public void onClickPressed(int x, int y) {
		this.clicked = true;
	}
	
	@Override
	public void onClickReleased(int x, int y) {
		this.clicked = false;
	}

	@Override
	public void onKeyTyped(char key){}
	
	@Override
	public void draw(int x, int y, int width, int height) {
		int col = clicked ? 150 : hovered ? 100 : 50;
		//int alpha = 255;
		stroke(col);
		fill(col);
		rect(x,y,width,height, 10);
		fill(255);
		textAlign(CENTER, CENTER);
		textSize(min(width, height) * 0.3);
		text(text, x + width / 2, y + height / 2);
		textSize(14);
	}
	
}

public abstract class WidgetBase implements Widget {
	
	int width;
	int height;
	boolean hasOverlay;
	int overlayWidth;
	int overlayHeight;

	public WidgetBase(){}
	
	public WidgetBase(int width, int height) {
		
		this.width = width;
		this.height = height;
	}
	
	OnClickPressedListener onClickPressedListener;
	OnClickReleasedListener onClickReleasedListener;
	OnMouseEnterListener onMouseEnterListener;
	OnMouseLeaveListener onMouseLeaveListener;
	OnMouseMoveListener onMouseMoveListener;
	OnKeyTypedListener onKeyTypedListener;
	
	public void setOnClickPressedListener(OnClickPressedListener listener) {
		this.onClickPressedListener = listener;
	}
	
	public void setOnClickReleasedListener(OnClickReleasedListener listener) {
		this.onClickReleasedListener = listener;
	}
	
	public void setOnMouseEnterListener(OnMouseEnterListener listener) {
		this.onMouseEnterListener = listener;
	}
	
	public void setOnMouseLeaveListener(OnMouseLeaveListener listener) {
		this.onMouseLeaveListener = listener;
	}
	
	public void setOnMouseMoveListener(OnMouseLeaveListener listener) {
		this.onMouseLeaveListener = listener;
	}

	public void setOnKeyTypedListener(OnKeyTypedListener listener) {
		this.onKeyTypedListener = listener;
	}
	
	
	
	@Override
	public int getWidth() {
		return this.width;
	}
	
	@Override
	public int getHeight() {
		return this.height;
	}
	
	@Override
	public boolean hasOverlay() {
		return this.hasOverlay;
	}
	
	@Override
	public int getOverlayWidth() {
		return this.overlayWidth;
	}
	
	@Override
	public int getOverlayHeight() {
		return this.overlayHeight;
	}
	
	@Override
	public OnClickPressedListener getOnClickPressedListener() {
		return onClickPressedListener;
	}
	
	@Override
	public OnClickReleasedListener getOnClickReleasedListener() {
		return onClickReleasedListener;
	}
	
	@Override
	public OnMouseEnterListener getOnMouseEnterListener() {
		return onMouseEnterListener;
	}
	
	@Override
	public OnMouseLeaveListener getOnMouseLeaveListener() {
		return onMouseLeaveListener;
	}
	
	@Override
	public OnMouseMoveListener getOnMouseMoveListener() {
		return onMouseMoveListener;
	}

	@Override
	public OnKeyTypedListener getOnKeyTypedListener() {
		return onKeyTypedListener;
	}
}

public interface Widget {
	
	public int getWidth();
	public int getHeight();
	public boolean hasOverlay();
	public int getOverlayWidth();
	public int getOverlayHeight();
	public OnClickPressedListener getOnClickPressedListener();
	public OnClickReleasedListener getOnClickReleasedListener();
	public OnMouseEnterListener getOnMouseEnterListener();
	public OnMouseLeaveListener getOnMouseLeaveListener();
	public OnMouseMoveListener getOnMouseMoveListener();
	public OnKeyTypedListener getOnKeyTypedListener();
	public void onMouseEnter(int x, int y);
	public void onMouseLeave(int x, int y);
	public void onMouseMove(int x, int y);
	public void onClickPressed(int x, int y);
	public void onClickReleased(int x, int y);
	public void onKeyTyped(char key);
	public void draw(int x, int y, int width, int height);
}

public class Position {
	private int x;
	private int y;
	private int width;
	private int height;
	
	public Position(int x, int y, int width, int height) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	public int getX() {
		return x;
	}
	
	public int getY() {
		return y;
	}
	
	public int getWidth() {
		return width;
	}
	
	public int getHeight() {
		return height;
	}
}


class GuiGridElementComparator implements Comparator<Widget>
{
	@Override public int compare(Widget elem1, Widget elem2)
	{
		return Boolean.compare(elem1.hasOverlay(), elem2.hasOverlay());
		
	}
}

public class GridLayout {
	private int rows;
	private int cols;
	private Map<Widget, Position> gridElementsMap;
	private List<Widget> gridElements;
	private Comparator<Widget> comparator = new GuiGridElementComparator();
	private boolean initialDrawn = false;
	
	PApplet parent;
	int width;
	int height;
	float cellWidth;
	float cellHeight;
	float padding;
	
	public GridLayout(PApplet parent, int rows, int cols, float padding) {
		this.gridElementsMap = new HashMap<Widget, Position>();
		this.gridElements = new ArrayList<Widget>();
		this.parent = parent;
		this.rows = rows;
		this.cols = cols;
		this.padding = padding;
		parent.registerMethod("pre", this);
		parent.registerMethod("draw", this);
		parent.registerMethod("mouseEvent", this);
		parent.registerMethod("keyEvent", this);
		pre();
		draw();
		initialDrawn = true;
	}
	
	void pre() {
		if (this.width != parent.width || this.height != parent.height) {
			this.width = parent.width;
			this.height = parent.height;
			this.cellWidth = (parent.width / (float)this.cols);
			this.cellHeight = (parent.height / (float)this.rows);
		}
	}
	
	public void addGridElement(Widget gridElement, int x, int y, int width, int height) {
		this.gridElementsMap.put(gridElement, new Position(x,y, width, height));
		this.gridElements.add(gridElement);
	}
	
	public void draw() {
		// TODO: sorting on every draw call is costly (though it is already sorted most of the time), but we
		// need to draw elements with "overlay" last so that the overlay appears on top of other elements
		// regardless of insertion order into the grid.
		// Maybe add a callback when setting overlay for an element and only then sort?
		Collections.sort(gridElements, comparator);
		for (Widget gridElement : gridElements) {
		 	Position pos = this.gridElementsMap.get(gridElement);
			int elementX = pos.getX();
			int elementY = pos.getY();
			int elementWidth = pos.getWidth();
			int elementHeight = pos.getHeight();
			
			int x = round(cellWidth * elementX + padding / 2);
			int y = round(cellHeight * elementY + padding / 2);
			int width = round(cellWidth * elementWidth - padding);
			int height = round(cellHeight * elementHeight - padding);
			gridElement.draw(x,y,width,height);
			
		}
	}
	
	private Widget getSelectedElement(int mouseX, int mouseY) {
		
		// here we want elements with overlay first! So we traverse the last backwards.
		ListIterator<Widget> li = gridElements.listIterator(gridElements.size());
		while(li.hasPrevious()) {
			Widget gridElement = li.previous();
			
		 	Position pos = this.gridElementsMap.get(gridElement);
			int elementX = pos.getX();
			int elementY = pos.getY();
			int elementWidth = pos.getWidth();
			int elementHeight = pos.getHeight();
			
			float startX = cellWidth * elementX + padding / 2;
			float startY = cellHeight * elementY + padding / 2;
			float endX = startX + cellWidth * elementWidth - padding;
			float endY = startY + cellHeight * elementHeight - padding;
			if (gridElement.hasOverlay()) {
				endX += gridElement.getOverlayWidth();
				endY += gridElement.getOverlayHeight();
			}
			
			if (mouseX >= startX && mouseX < endX && mouseY >= startY && mouseY < endY) {
				return gridElement;
			}
		} 
		return null; 
	}

	public void keyEvent(KeyEvent event){
		if(event.getAction() == KeyEvent.RELEASE){

			for(Widget widget : gridElements){
				widget.onKeyTyped(event.getKey());
				if (widget.getOnKeyTypedListener() != null) {
					widget.getOnKeyTypedListener().onKeyTyped(event.getKey());
				}
			}
		}
	}

	
	Widget prevElement;
	public void mouseEvent(MouseEvent event) {
		if(!initialDrawn){
			return;
		}
		Widget gridElement = getSelectedElement(event.getX(), event.getY());
		
		if (prevElement != null && prevElement != gridElement) {
			prevElement.onMouseLeave(event.getX(), event.getY());
			if (prevElement.getOnMouseLeaveListener() != null) {
				prevElement.getOnMouseLeaveListener().onMouseLeave(event.getX(), event.getY());
			}
			prevElement = null;
		}
		
		if (gridElement == null) {
			return;
		}
		
		switch(event.getAction()) {
			case MouseEvent.MOVE:
			case MouseEvent.DRAG:
			if (prevElement != gridElement) {
				gridElement.onMouseEnter(event.getX(), event.getY());
				if (gridElement.getOnMouseEnterListener() != null) {
					gridElement.getOnMouseEnterListener().onMouseEnter(event.getX(), event.getY());
				}
			} else {
				gridElement.onMouseMove(event.getX(), event.getY());
				if (gridElement.getOnMouseMoveListener() != null) {
					gridElement.getOnMouseMoveListener().onMouseMove(event.getX(), event.getY());
				}
			}
			
			break;
			case MouseEvent.PRESS:
			gridElement.onClickPressed(event.getX(), event.getY());
			if (gridElement.getOnClickPressedListener() != null) {
				gridElement.getOnClickPressedListener().onClickPressed(event.getX(), event.getY());
			}
			break;
			case MouseEvent.RELEASE:
			gridElement.onClickReleased(event.getX(), event.getY());
			if (gridElement.getOnClickReleasedListener() != null) {
				gridElement.getOnClickReleasedListener().onClickReleased(event.getX(), event.getY());
			}
			break;
		}
		prevElement = gridElement;
	}
	
}
