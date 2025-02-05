module debug

pub infixl 10 (+++)

pub fun stringb/(+++)(x : string, y : string) : string
    x ++ y

pub fun stringl/(+++)(x : string, y : a, ?show : a -> string) : string
    x ++ show(y)

pub fun stringr/(+++)(x : a, y : string, ?show : a -> string) : string
    show(x) ++ y

pub fun (+++)(x : a, y : b, ?a/show : a -> string, ?b/show : b -> string) : string
    a/show(x) ++ b/show(y)
