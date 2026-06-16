public class CommentsHandling {
    public static void main(String[] args) {
        // This line comment should be ignored by the lexer.
        int value = 1;
        /*
           This block comment should also be ignored.
        */
        value = value + 2;
        System.out.println(value);
    }
}
