id = (...) -> ...
pack = (...) -> {...}
map = (f) -> (t) -> [f x for x in *t]
show = (d) ->
  if type(d) == 'table'
    if #d > 0
      "{#{table.concat ((map show) d), ','}}"
    else
      u = {}
      for k, v in pairs d
        table.insert u, "#{k}:#{show v}"
      "{#{table.concat u, ','}}"
  else
    tostring(d)
dup = map id
mapT = (f) -> (t) -> {k, f v for k, v in pairs t}
dupT = mapT id
head = (t) -> t[1]
tail = (t) ->
  with u = dup t
    table.remove u, 1
take = (t, i) ->
  u = {}
  v = dup t
  for j = 1, i
    u[j] = v[1]
    table.remove v, 1
  return u, v
puton = (t, k) ->
  with u = dupT t
    u[k] = 0 if type(u[k]) ~= 'number'
    u[k] += 1
pickup = (t, k) ->
  if type(t[k]) == 'number' and t[k] > 0
    with u = dupT t
      u[k] -= 1
append = (t, v) ->
  with u = dup t
    for i in *v
      table.insert u, i
concat = (t) ->
  with u = {}
    for v in *t
      for w in *v
        table.insert u, w
monad = (join, fmap) -> (m, k) ->
  join (fmap k) m
mplus = (map, bind, pure, zero, plus) -> {:map, :bind, :pure, :zero, :plus}
maybe_map = (f) -> (v) -> if v == nil then nil else f v
maybe_plus = (u, v) -> if u ~= nil then u else v
mplus_list = mplus map, (monad concat, map), pack, {}, append
mplus_maybe = mplus maybe_map, (monad id, maybe_map), id, nil, maybe_plus
fst = (f) -> (f!)
snd = (f) ->
  _, s = f!
  s
mklazylist = (t) -> ->
  if #t > 0
    return (head t), (mklazylist tail t)
  else
    nil
unlazylist = (l) ->
  with u = {}
    x, l = l!
    while x ~= nil
      table.insert u, x
      x, l = l!
takeL = (l, i) ->
  with u = {}
    for j = 1, i
      x, l = l!
      table.insert u, x
mapL = (f) -> (l) -> ->
  h, t = l!
  return nil if h == nil
  (f h), (mapL f) t
appendL = (k, l) -> ->
  h, t = k!
  if h ~= nil
    return h, appendL t, l
  return l!
concatL = (l) -> ->
  h, t = l!
  return nil if h == nil
  return (appendL h, concatL t)!
pureL = (x) -> mklazylist { x }
zeroL = ->
mplus_lazylist = mplus mapL, monad(concatL, mapL), pureL, zeroL, appendL
seq = (a, b) ->
  with u = {}
    for i = a, b
      table.insert u, i
keys = (t) -> [k for k, _ in pairs t]
foldl = (f) -> (x, t) ->
  for v in *t
    x = f x, v
  return x
foldr = (f) -> (x, t) ->
  for i = #t, 1, -1
    x = f x, t[i]
  return x

match_one = (mplus, env, value, datatype, pattern) ->
  datatype[head pattern] mplus, env, value, unpack tail pattern

match_with = (mplus) -> (target, datatype, patterns) -> 
  for p, f in pairs patterns
    envM = match_one mplus, {}, target, datatype, p
    return (mplus.map f) envM if envM ~= mplus.zero
  return mplus.zero

match_all = match_with mplus_list
match_lazy = match_with mplus_lazylist

match = (...) -> fst (match_lazy ...)

loop = (range, middle, tail) ->
  (foldr (x, v) -> v x) tail, (map (i) -> (l) -> middle l, i) range

bindvar = (env, name, v) ->
  if name == nil then env
  else with e = dupT env
    e[name] = v

var = (name) -> { var, name }
val = (exp) -> { val, exp }
cons = (h, t) -> { cons, h, t }
join = (x, y) -> { join, x, y }
empty = -> { empty }

mkmultiset = (t) ->
  with u = {}
    for k in *t
      u[k] = 0 if u[k] == nil
      u[k] += 1

unmultiset = (m) ->
  with u = {}
    for k, v in pairs m
      for i = 1, v
        table.insert u, k

multiset_le = (a, b) ->
  for k, v in pairs a
    n = a[k] or 0
    m = b[k] or 0
    if not n <= m return false
  return true

multiset_eq = (a, b) ->
  multiset_le(a, b) and multiset_le(b, a)

List = (datatype) -> {
  [cons]: (mplus, env, v, hp, tp) ->
    if type(v) == 'table' and #v > 0
      mplus.bind (match_one mplus, env, (head v), datatype, hp), (env) ->
        match_one mplus, env, (tail v), (List datatype), tp
    else
      mplus.zero
  [join]: (mplus, env, v, xp, yp) ->
    if type(v) == 'table' and #v > 0
      f = map (i) ->
        xs, ys = take v, i
        mplus.bind (match_one mplus, env, xs, (List datatype), xp), (env) ->
          match_one mplus, env, ys, (List datatype), yp
      (foldl mplus.plus) mplus.zero, f (seq 0, #v)
    else
      mplus.zero
  [var]: (mplus, env, v, name) ->
    if type(v) == 'table'
      for i in *v
        if match_one(mplus, env, i, datatype, var!) == mplus.zero
          return mplus.zero
      mplus.pure bindvar env, name, v
    else mplus.zero
  [val]: (mplus, env, v, exp) ->
    if type(v) == 'table' and v == exp(env)
      mplus.pure env
    else mplus.zero
  [empty]: (mplus, env, v) ->
    if type(v) == 'table' and #v == 0
      mplus.pure env
    else mplus.zero
}

Multiset = (datatype) -> {
  [cons]: (mplus, env, v, hp, tp) ->
    if type(v) == 'table'
      f = map (k) ->
        u = pickup v, k
        mplus.bind (match_one mplus, env, k, datatype, hp), (env) ->
          match_one mplus, env, u, (Multiset datatype), tp
      (foldl mplus.plus) mplus.zero, f keys(v)
    else
      mplus.zero
  [var]: (mplus, env, v, name) ->
    if type(v) == 'table'
      for k, _ in pairs v
        if match_one(mplus, env, k, datatype, var!) == mplus.zero
          return mplus.zero
      mplus.pure bindvar env, name, v
    else mplus.zero
  [val]: (mplus, env, v, exp) ->
    if type(v) == 'table' and multiset_eq v, exp(env)
      mplus.pure env
    else mplus.zero
  [empty]: (mplus, env, v) ->
    if type(v) == 'table' and #(unmultiset v) == 0
      mplus.pure env
    else mplus.zero
}

Number = {
  [var]: (mplus, env, v, name) ->
    if type(v) == 'number'
      mplus.pure bindvar env, name, v
    else mplus.zero
  [val]: (mplus, env, v, exp) ->
    if type(v) == 'number' and v == exp(env)
      mplus.pure env
    else mplus.zero
}

Something = {
  [var]: (mplus, env, v, name) -> mplus.pure bindvar env, name, v
}

{
  :List, :Multiset, :Number, :Something, :var, :val, :cons, :join, :match, :match_all,
  :match_lazy, :mkmultiset, :unmultiset, :mklazylist, :unlazylist, :empty, :loop
}
