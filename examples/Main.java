public class Main {
    public static void main(String[] args) {
        int x = 3;
        while (x < 5) {
            x = x + 1;
        }

        if (x >= 5) {
            System.out.println(add(x, 2));
        } else {
            System.out.println(0);
        }
    }

    public static int add(int a, int b) {
        return a + b;
    }
}
