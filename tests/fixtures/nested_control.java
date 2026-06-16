public class NestedControl {
    public static void main(String[] args) {
        int i = 0;
        int hits = 0;
        while (i < 5) {
            if (i > 2) {
                hits = hits + 1;
            } else {
                hits = hits;
            }
            i = i + 1;
        }
        System.out.println(hits);
    }
}
