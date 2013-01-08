for k, v in pairs require 'egimoon'
  _G[k] = v

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
foldl = (f) -> (x, t) ->
  for v in *t
    x = f x, v
  return x
seq = (a, b) ->
  with u = {}
    for i = a, b
      table.insert u, i

print show match_all {1, 2, 3}, (List Number),
  [cons var('x'), var('ts')]: => {@x, @ts}

print show match_all (mkmultiset {1, 2, 3}), (Multiset Number),
  [cons var('x'), var('ts')]: => {@x, (unmultiset @ts)}

print show match_all {1, 2, 3}, (List Number),
  [join var('xs'), var('ys')]: => {@xs, @ys}

print show match_all {1, 1, 2, 3}, (List Number),
  [cons var('n'), cons val(=> @n), var!]: => @n

print show match_all (mkmultiset {1, 2, 3, 1, 2}), (Multiset Number),
  [cons var('n'), cons val(=> @n), var!]: => @n

print show match_all (mkmultiset {1, 2, 3}), (Multiset Number),
  [cons var('x'), cons var('y'), cons var('z'), empty!]: => {@x, @y, @z}

print show match_all {1, 2, 3, 4}, (List Number),
  [join var!, cons var('m'), join var!, cons var('n'), var!]: => {@m, @n}

combination = (xs, k) ->
  pattern = loop (seq 1, k), ((l, i) -> join var!, cons var(i), l), var!
  match_all xs, (List Something),
    [pattern]: => @

print show combination {1, 2, 3, 4}, 3
