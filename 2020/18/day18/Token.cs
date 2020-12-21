namespace day18
{
    public class Token
    {
        public TokenType TokenType;

        public long? Value;

        public string Lexeme;

        public Token(TokenType tokenType,
                     string lexeme,
                     int? value)
        {
            this.TokenType = tokenType;
            this.Lexeme = lexeme;
            this.Value = value;
        }
    }
}