import java.util.Objects;

public class Coordinate {

	private int x;
	private int y;

    public static Coordinate EmptyCoordinate = new Coordinate(-1,-1);

	public Coordinate(int x, int y) {
		this.x = x;
		this.y = y;
	}
	int getX() {
		return this.x;
	}
	int getY() {
		return this.y;
	}
	void setX(int x) {
		this.x = x;
	}
	void setY(int y) {
		this.y = y;
	}
	void setXY(int x, int y) {
		this.x = x;
		this.y = y;
	}

	@Override
	public boolean equals(Object o) {
		if (o == this)
			return true;
		if (!(o instanceof Coordinate)) {
			return false;
		}
		Coordinate coordinate = (Coordinate) o;
		return x == coordinate.x && y == coordinate.y;
	}

	@Override
	public int hashCode() {
		return Objects.hash(x, y);
	}

	@Override
	public String toString(){
		return "Coordinate: ("+this.x+","+this.y+")";
	}
}