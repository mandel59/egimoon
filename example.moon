import List, Number, var, val, cons, join, match_all from require 'egimoon'

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

print show match_all {1, 2, 3}, (List Number),
  [cons var('x'), var('ts')]: => {@x, @ts}

print show match_all {1, 2, 3}, (List Number),
  [join var('xs'), var('ys')]: => {@xs, @ys}

print show match_all {1, 1, 2, 3}, (List Number),
  [cons var('n'), cons val(=> @n), var!]: => @n
