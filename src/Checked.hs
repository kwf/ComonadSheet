{-# LANGUAGE GADTs, RankNTypes, StandaloneDeriving #-}

module Checked where

import Control.Applicative hiding (empty)
import Control.Applicative.Free
import Data.Traversable
import Data.Set (Set, empty, insert, fromList, union)

-- | A 'CellRef' is a reference of type r from a container of things of type b, which results in something of type v. When dereferenced, a plain 'CellRef' will always give a result of type b, but used in a free applicative functor, v varies over the result type of the expression.
data CellRef r b v where
  Ref :: r -> CellRef r b b
deriving instance (Show r) => Show (CellRef r b v)

-- | A 'CellExpr' is the free applicative functor over 'CellRefs'. A 'CellExpr' is an expression using references of type r to a container of things of type b, whose result is something of type v.
type CellExpr r b v = Ap (CellRef r b) v

-- | Extracts the reference from a 'CellRef'.
getRef :: CellRef r b v -> r
getRef (Ref r) = r

-- | A 'Deref' is a synonym for a function which knows how, given an index, to take something out of a structure, but isn't allowed to think about the items in the structure themselves.
type Deref f r = forall x. r -> f x -> x

-- | Given an appropriate method of dereferencing and a 'CellRef', uses the 'CellRef' to extract something from a structure.
deref :: Deref f r -> CellRef r b v -> f b -> v
deref f (Ref r) = f r

-- | Returns the set of all references in a 'CellExpr'.
references :: Ord r => CellExpr r b v -> Set r
references (Pure _)       = empty
references (Ap (Ref r) x) = insert r (references x)

-- | Given an appropriate method of dereferencing and a 'CellExpr', returns the function from a structure to a value which is represented by a 'CellExpr'.
runCell :: Deref f r -> CellExpr r b v -> f b -> v
runCell f = runAp (deref f)

-- | Constructs a 'CellExpr' which evaluates to whatever is at index r.
cell :: r -> CellExpr r b b
cell = liftAp . Ref

-- | Constructs a 'CellExpr' which evaluates to the list of things referenced by the references in the indices given.
cells :: [r] -> CellExpr r b [b]
cells = traverse cell
