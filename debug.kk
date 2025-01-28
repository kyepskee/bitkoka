module debug

pub infixl 10 (+++)

pub fun (+++)(x : a, y : b, ?a/show : a -> string, ?b/show : b -> string) : string
    a/show(x) ++ b/show(y)
