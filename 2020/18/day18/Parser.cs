using System;
using System.Collections.Generic;

using static day18.TokenType;

namespace day18
{
    public class Parser
    {
        #region Fields

        private int current;

        private List<Token> tokens;

        #endregion

        #region Instance Methods

        public Expr Parse(List<Token> tokens)
        {
            this.tokens = tokens;

            while (!this.IsAtEnd())
            {
                return this.Expression();
            }

            throw new Exception("Expected expression.");
        }

        protected virtual Expr ParseMathExpr()
        {
            Expr expr = this.Primary();

            while (this.Match(Plus,
                              Star))
            {
                Token op = this.Previous();
                Expr right = this.Primary();
                expr = new MathExpr(expr,
                                    op,
                                    right);
            }

            return expr;
        }

        protected Token Advance()
        {
            if (!this.IsAtEnd())
            {
                this.current++;
            }

            return this.Previous();
        }

        protected bool Check(TokenType tokenType)
        {
            if (this.IsAtEnd())
            {
                return false;
            }

            return this.Peek()
                       .TokenType
                   == tokenType;
        }

        protected Token Consume(TokenType tokenType,
                              string err)
        {
            if (this.Check(tokenType))
            {
                return this.Advance();
            }

            throw new Exception(err);
        }

        protected Expr Expression()
        {
            return this.ParseMathExpr();
        }

        protected bool IsAtEnd() =>
            this.Peek()
                .TokenType
            == Eof;

        protected bool Match(params TokenType[] tokenTypes)
        {
            for (int i = 0;
                 i < tokenTypes.Length;
                 i++)
            {
                if (this.Check(tokenTypes[i]))
                {
                    this.Advance();
                    return true;
                }
            }

            return false;
        }

        protected Token Peek() => this.tokens[this.current];

        protected Token Previous() => this.tokens[this.current - 1];

        protected Expr Primary()
        {
            if (this.Match(Number))
            {
                return new LiteralExpr(this.Previous());
            }

            if (this.Match(LeftParen))
            {
                var expr = this.Expression();
                this.Consume(RightParen,
                             "Expect ')' at the end of a grouping expression");
                return new GroupExpr(expr);
            }

            throw new Exception($"Unexpected token type {this.Previous().TokenType}");
        }

        #endregion
    }
}