SELECT bloom_contains((SELECT bloom_agg(g) FROM generate_series(1, 100) AS g), x) FROM generate_series(1, 110) AS x;

SELECT bloom_contains(
    (SELECT bloom_union_agg(bf) FROM  
      (SELECT bloom_agg(g) AS bf FROM generate_series(1, 100) AS g
        UNION ALL
       SELECT bloom_agg(g) AS bf FROM generate_series(101, 200) AS g) _), x)
FROM generate_series(1, 210) AS x;
