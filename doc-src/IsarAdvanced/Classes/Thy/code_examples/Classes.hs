module Classes where {


data Nat = Suc Nat | Zero_nat;

nat_aux :: Integer -> Nat -> Nat;
nat_aux i n = (if i <= 0 then n else nat_aux (i - 1) (Suc n));

nat :: Integer -> Nat;
nat i = nat_aux i Zero_nat;

class Semigroup a where {
  mult :: a -> a -> a;
};

class (Semigroup a) => Monoidl a where {
  neutral :: a;
};

class (Monoidl a) => Monoid a where {
};

class (Monoid a) => Group a where {
  inverse :: a -> a;
};

inverse_int :: Integer -> Integer;
inverse_int i = negate i;

neutral_int :: Integer;
neutral_int = 0;

mult_int :: Integer -> Integer -> Integer;
mult_int i j = i + j;

instance Semigroup Integer where {
  mult = mult_int;
};

instance Monoidl Integer where {
  neutral = neutral_int;
};

instance Monoid Integer where {
};

instance Group Integer where {
  inverse = inverse_int;
};

pow_nat :: forall a. (Monoid a) => Nat -> a -> a;
pow_nat (Suc n) x = mult x (pow_nat n x);
pow_nat Zero_nat x = neutral;

pow_int :: forall a. (Group a) => Integer -> a -> a;
pow_int k x =
  (if 0 <= k then pow_nat (nat k) x
    else inverse (pow_nat (nat (negate k)) x));

example :: Integer;
example = pow_int 10 (-2);

}
