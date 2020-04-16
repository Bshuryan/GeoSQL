-- show_playlists_by_user: given a user_id, displays all playlists by that user
drop procedure if exists show_playlists_by_user;
delimiter //
create procedure show_playlists_by_user(IN usr_id INT)
    begin
		select PLAYLIST_ID from PLAYLIST where PLAYLIST.USER_ID = usr_id;
	end //
delimiter ;


-- create_playlist: given a user_id and playlist name, creates a new playlist
drop procedure if exists create_playlist;
delimiter //
create procedure create_playlist(
    IN usr_id INT, 
    IN playlist_title VARCHAR(45)
    )
begin 
    INSERT INTO PLAYLIST(USER_ID, PLAYLIST_DATE_CREATED, PLAYLIST_DATE_MODIFIED, PLAYLIST_NAME)
    VALUES(usr_id, NOW(), NOW(), playlist_title);
end //
delimiter ;


-- delete_playlist: deletes the instance associated with a given playlist_id
drop procedure if exists delete_playlist;
delimiter //
create procedure delete_playlist(
    IN playlst_id INT 
    )
begin 
	DELETE FROM PLAYLIST WHERE PLAYLIST_ID = playlst_id;
    
end //
delimiter ;




-- add_song_to_playlists: given a song and playlist_id, adds the song to the chosen playlist
drop procedure if exists add_song_to_playlists;
delimiter //
create procedure add_song_to_playlist(IN current_song_id INT, IN usr_playlist_id INT)
    BEGIN
        insert into SONG_IN_PLAYLIST(PLAYLIST_ID, SONG_ID, SIP_DATE_ADDED)
            VALUES(usr_playlist_id, current_song_id, NOW());
            
        UPDATE PLAYLIST set PLAYLIST_DATE_MODIFIED = NOW() WHERE PLAYLIST_ID = usr_playlist_id;
    END //
    delimiter ;
    




-- play: executes when a user plays any given song outside of a playlist
drop procedure if exists play;
DELIMITER //
CREATE PROCEDURE play(current_song_id INT, usr_id INT)
    BEGIN 
        insert into USER_PLAYING_SONG(USER_ID, SONG_ID, PLAY_TIME)
            values(usr_id, current_song_id, NOW());
        update SONG set SONG_TIMES_PLAYED = SONG_TIMES_PLAYED + 1 where song_id = current_song_id;
        
    END //
DELIMITER ;




-- play_from_playlist: executes when a user plays any given song from within a playlist
drop procedure if exists play_from_playlist;
DELIMITER //
CREATE PROCEDURE play_from_playlist(current_song_id INT, usr_id INT, usr_playlist_id INT)
    BEGIN 
        insert into USER_PLAYING_SONG(USER_ID, SONG_ID, PLAY_TIME)
            VALUES(usr_id, current_song_id, NOW());
            
        UPDATE SONG SET SONG_TIMES_PLAYED = SONG_TIMES_PLAYED + 1 
            WHERE song_id = current_song_id;
            
        UPDATE SONG_IN_PLAYLIST SET SIP_TIMES_PLAYED = SIP_TIMES_PLAYED + 1
            WHERE SONG_ID = current_song_id
            AND PLAYLIST_ID = usr_playlist_id;
            
    END //
DELIMITER ;


-- show_songs_in_playlist: given a user's playlist id, show all songs related to that playlist
drop procedure if exists show_songs_in_playlist;
DELIMITER //
CREATE PROCEDURE show_songs_in_playlist(usr_playlist_id INT)
    BEGIN
        SELECT SONG.SONG_ID, SONG_NAME as Song, SONG_ARTIST as Artist, SONG_GENRE as Genre, SEC_TO_TIME(SONG_DURATION) as Length
        FROM SONG_IN_PLAYLIST, SONG WHERE SONG_IN_PLAYLIST.PLAYLIST_ID = usr_playlist_id 
        AND SONG_IN_PLAYLIST.SONG_ID = SONG.SONG_ID
        ORDER BY SONG_IN_PLAYLIST.SIP_DATE_ADDED DESC;
    END //
DELIMITER ;


-- show_songs_of_genre: given a certain genre, display all songs available that belong to that genre
drop procedure if exists show_songs_of_genre;
DELIMITER //
create procedure show_songs_of_genre(IN genre VARCHAR(50))
	begin
		select SONG.SONG_ID, SONG_NAME as Song, SONG_ARTIST as Artist, SONG_GENRE as Genre, SEC_TO_TIME(SONG_DURATION) as Length
        from SONG where SONG_GENRE = genre
        order by song;
	end //
delimiter ;
call show_songs_of_genre('classic rock');


-- show_all_songs: displays all available songs, ordered alphabetically in ascending order
drop procedure if exists show_all_songs;
delimiter //
create procedure show_all_songs()
	begin
		select SONG.SONG_ID, SONG_NAME as Song, SONG_ARTIST as Artist, SONG_GENRE as Genre, SEC_TO_TIME(SONG_DURATION) as Length
        from SONG
        order by SONG_NAME;
	end //
delimiter ;
call show_all_songs();


-- show_songs_by_artist: displays all songs created by the given artist
drop procedure if exists show_songs_by_artist;
delimiter //
create procedure show_songs_by_artist(IN artist_name VARCHAR(60))
	begin
		select SONG.SONG_ID, SONG_NAME as Song, SONG_ARTIST as Artist, SONG_GENRE as Genre, SEC_TO_TIME(SONG_DURATION) as Length
        from SONG where SONG_ARTIST = artist_name
        order by SONG_NAME;
        end //
	delimiter ;


-- search_library: given user input, returns all songs where either the song name or artist matches
drop procedure if exists search_library;
delimiter //
create procedure search_library(IN usr_search VARCHAR(100))
	begin 
		select SONG.SONG_ID, SONG_NAME as Song, SONG_ARTIST as Artist, SONG_GENRE as Genre, SEC_TO_TIME(SONG_DURATION) as Length
        from SONG
        where SONG_NAME like CONCAT('%', usr_search, '%') 
        OR SONG_ARTIST like CONCAT('%', usr_search, '%')
        order by SONG_NAME;
	end //
delimiter ;



-- get_distance_score: helper function for show_geosounds procedure which assigns a value to each song based on how near it was played from the user given the user's location
drop function if exists get_distance_score;
delimiter //
create function get_distance_score(lat_a DOUBLE, lat_b DOUBLE, long_a DOUBLE, long_b DOUBLE)
	returns int
    begin
		DECLARE distance DOUBLE;
        SET distance = 111.111 *
			DEGREES(ACOS(LEAST(1.0, COS(RADIANS(lat_a))
			 * COS(RADIANS(lat_b))
			 * COS(RADIANS(long_a - long_b))
			 + SIN(RADIANS(lat_a))
			 * SIN(RADIANS(lat_b)))));
		IF distance > 750 THEN 
			RETURN 1;
		ELSEIF distance > 600 THEN 
			RETURN 2;
		ELSEIF distance > 450 THEN 
			RETURN 3;
		ELSEIF distance > 325 THEN 
			RETURN 4;
		ELSEIF distance > 225 THEN
			RETURN 5;
		ELSEIF DISTANCE > 150 THEN 
			RETURN 6;
		ELSEIF DISTANCE > 100 THEN 
			RETURN 7;
		ELSEIF DISTANCE > 50 THEN 
			RETURN 8;
		ELSEIF DISTANCE > 25 THEN
			RETURN 9;
		ELSE
			RETURN 10;
			
		END IF;
	end //
delimiter ;


-- get_recency_score: helper function for show_geosounds procedure which assigns a value to each song based on how recenctly it was played
drop function if exists get_recency_score;
delimiter //
create function get_recency_score(date_played DATETIME)
	returns INT
	begin
		declare days_since_played INT;
        set days_since_played = TIMESTAMPDIFF(DAY, date_played, NOW());

        IF days_since_played <= 1 THEN
			return 5;
        ELSEIF days_since_played <= 3 THEN
			return 4;
        ELSEIF days_since_played <= 7 THEN
			return 3;
		ELSEIF days_since_played <= 14 THEN
			return 2;
		ELSEIF days_since_played <= 30 THEN
			return 1;
        ELSE
			return 0;
		END IF;
    
    end //
delimiter ;


-- show_geosounds: outputs top 10 ranking of songs based on location, popularity, and recency
drop procedure if exists show_geosounds;
delimiter //
create procedure show_geosounds(IN usr_id INT)
	begin
		DECLARE USER_LAT DOUBLE;
        DECLARE USER_LONG DOUBLE;
        SET USER_LAT = (select CITY.CITY_LAT 
			from USER, LOCATION, CITY 
            where USER.USER_ID = usr_id 
            AND USER.LOC_ID = LOCATION.LOC_ID
            AND LOCATION.CITY_ID = CITY.CITY_ID);
		SET USER_LONG = (select CITY.CITY_LONG 
			from USER, LOCATION, CITY 
            where USER.USER_ID = usr_id 
            AND USER.LOC_ID = LOCATION.LOC_ID
            AND LOCATION.CITY_ID = CITY.CITY_ID);
            
        select SONG_ID, SONG_NAME as Song, SONG_ARTIST as Artist, SONG_GENRE as Genre, SEC_TO_TIME(SONG_DURATION) as Length, GeoScore from (
			select SONG_ID, SONG_NAME, SONG_ARTIST, SONG_GENRE, SONG_DURATION, SUM(GEO_SCORE) as GeoScore
			from( 
				select SONG.SONG_ID as SONG_ID, SONG_NAME, SONG_ARTIST, SONG_GENRE, SONG_DURATION, 
					get_distance_score(USER_LAT, CITY.CITY_LAT, USER_LONG, CITY.CITY_LONG) 
					+ get_recency_score(USER_PLAYING_SONG.PLAY_TIME) as GEO_SCORE
				from USER_PLAYING_SONG, SONG, USER, CITY, LOCATION 
				where USER_PLAYING_SONG.SONG_ID = SONG.SONG_ID 
					AND USER_PLAYING_SONG.USER_ID = USER.USER_ID
					AND USER.LOC_ID = LOCATION.LOC_ID
					AND LOCATION.CITY_ID = CITY.CITY_ID
					AND USER.USER_ID <> usr_id
				) AS GEO_DATA
			group by SONG_ID
			order by sum(GEO_SCORE) desc, SONG_NAME ) AS GEO_INFO
			limit 10; 
	end //
delimiter ;




