public class BooleanAndOr {
    public static void main(String[] args) {
        boolean ready = true;
        boolean blocked = false;
        if (ready && blocked || ready) {
            System.out.println("go");
        } else {
            System.out.println("stop");
        }
    }
}
