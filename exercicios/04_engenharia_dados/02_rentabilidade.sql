%%sql zoo
ALTER TABLE recinto 
ADD COLUMN IF NOT EXISTS rentabilidade REAL;