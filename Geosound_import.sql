-- importing SONG data obtained from https://www.kaggle.com/iamsumat/spotify-top-2000s-mega-dataset/data#
LOAD DATA 
LOCAL INFILE 'Spotify-2000.csv' INTO TABLE SONG
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(SONG_ID, SONG_NAME, SONG_ARTIST, SONG_GENRE, SONG_YEAR, SONG_DURATION);


-- importing CITY data obtained from https://simplemaps.com/data/us-cities 
LOAD DATA 
LOCAL INFILE 'uscities.csv' INTO TABLE CITY
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(CITY_NAME, CITY_STATE, CITY_LAT, CITY_LONG, CITY_ZIPS, CITY_ID);

