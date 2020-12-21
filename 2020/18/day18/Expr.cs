using System;
using System.Collections.Generic;
using System.Text;

namespace day18
{
    public abstract class Expr
    {
    }

    public class GroupExpr : Expr
    {
        public Expr Inner;
        public GroupExpr (Expr inner)
        {
            this.Inner = inner;
        }
    }

    public class MathExpr: Expr
    {
        public Expr Left;

        public Token Op;

        public Expr Right;

        public MathExpr(Expr left, Token op, Expr right)
        {
            this.Left = left;
            this.Op = op;
            this.Right = right;
        }
    }

    public class LiteralExpr: Expr
    {
        public Token Token;

        public LiteralExpr(Token token)
        {
            this.Token = token;
        }
    }
}
