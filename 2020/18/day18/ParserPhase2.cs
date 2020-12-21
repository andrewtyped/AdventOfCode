namespace day18
{
    public class ParserPhase2 : Parser
    {
        protected override Expr ParseMathExpr()
        {
            return this.ParseMultiplication();
        }

        private Expr ParseAddition()
        {
            Expr expr = this.Primary();

            while (this.Match(TokenType.Plus))
            {
                Token op = this.Previous();
                Expr right = this.Primary();
                expr = new MathExpr(expr,
                                    op,
                                    right);
            }

            return expr;
        }

        private Expr ParseMultiplication()
        {
            Expr expr = this.ParseAddition();

            while (this.Match(TokenType.Star))
            {
                Token op = this.Previous();
                Expr right = this.ParseAddition();
                expr = new MathExpr(expr,
                                    op,
                                    right);
            }

            return expr;
        }
    }
}