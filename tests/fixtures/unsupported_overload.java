public class UnsupportedOverload {
    public static int value(int input) {
        return input;
    }

    public static double value(double input) {
        return input;
    }

    public static void main(String[] args) {
        System.out.println(value(1));
    }
}
