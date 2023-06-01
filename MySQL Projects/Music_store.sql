/*Creating database*/
create database Music_Store;
use Music_Store;

/*Creating employee table*/ 
CREATE table employee(
	employee_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    title VARCHAR(50) NOT NULL,
    reports_to VARCHAR(30),
    levels VARCHAR(10),
    birthdate VARCHAR(30),
    hire_date VARCHAR(30),
    address VARCHAR(120),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(30),
    postal_code VARCHAR(30),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(150)
);

/* Creating Customer Table*/
CREATE TABLE customer(
	customer_id INT AUTO_INCREMENT PRIMARY KEY,
	first_name VARCHAR(100) NOT NULL,
	last_name VARCHAR(100) NOT NULL,
    company VARCHAR(100) NOT NULL,
    address VARCHAR(150),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(50),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(150),
    support_rep_id INT NOT NULL,
    FOREIGN KEY(support_rep_id) REFERENCES employee(employee_id) ON DELETE CASCADE
);
 
 /* Creating Invoice Table*/
CREATE TABLE invoice(
	invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    invoice_date VARCHAR(30),
    billing_address VARCHAR(150),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_country VARCHAR(100),
    billing_postal_code VARCHAR(100),
    total VARCHAR(30),
    FOREIGN KEY(customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE
);

/* Creating Artist Table*/
CREATE TABLE artist(
	artist_id INT AUTO_INCREMENT PRIMARY KEY,
    artist_name VARCHAR(80)
);

/* Creating Genre Table*/
CREATE TABLE genre(
	genre_id INT AUTO_INCREMENT PRIMARY KEY,
    genre_name VARCHAR(150)
);

/* Creating media_type Table*/ 
 CREATE TABLE media_type(
	media_type_id INT AUTO_INCREMENT PRIMARY KEY,
    media_type_name VARCHAR(150)
);
 
 /* Creating Playlist Table*/
 CREATE TABLE playlist(
	playlist_id  INT AUTO_INCREMENT PRIMARY KEY,
    playlist_name VARCHAR(150)
);

/* Creating Album Table*/
CREATE TABLE album(
	album_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100),
    artist_id INT NOT NULL,
    FOREIGN KEY(artist_id) REFERENCES artist(artist_id) ON DELETE CASCADE
);
 
 /* Creating Track Table*/
 CREATE TABLE track(
	track_id INT AUTO_INCREMENT PRIMARY KEY,
    track_name VARCHAR(150),
    album_id INT NOT NULL,
    media_type_id INT NOT NULL,
    genre_id INT NOT NULL,
    composer VARCHAR(150),
    milliseconds VARCHAR(30),
    bytes VARCHAR(30),
    unit_price DECIMAL(3,2),
    FOREIGN KEY(album_id) REFERENCES album(album_id) ON DELETE CASCADE,
    FOREIGN KEY(media_type_id) REFERENCES media_type(media_type_id) ON DELETE CASCADE,
    FOREIGN KEY(genre_id) REFERENCES genre(genre_id) ON DELETE CASCADE
);
 
 /* Creating Invoice_line Table*/
CREATE TABLE invoice_line(
	invoice_line_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    track_id INT NOT NULL,
    unit_price VARCHAR(30),
    quantity VARCHAR(50),
    FOREIGN KEY(invoice_id) REFERENCES invoice(invoice_id) ON DELETE CASCADE,
    FOREIGN KEY(track_id) REFERENCES track(track_id)
);

/* Creating  Playlist_track Table*/
CREATE TABLE playlist_track(
	playlist_id  INT NOT NULL,
    track_id INT NOT NULL,
    FOREIGN KEY(playlist_id) REFERENCES playlist(playlist_id) ON DELETE CASCADE,
    FOREIGN KEY(track_id) REFERENCES track(track_id) ON DELETE CASCADE
);
 
/* Selecting contents from the table*/
select * from employee;
select * from customer;
select * from invoice;
select * from artist;
select * from genre;
select * from media_type;
select * from playlist;
select * from album;  
select * from track;    
select * from invoice_line;    
select * from playlist_track;    
 
/*1. Who is the senior most employee based on job title?*/
select * from employee;
select concat(first_name,' ',last_name) as employee, title, levels
from employee
order by levels desc limit 1;

# 2. Which countries have the most Invoices?
select count(*) as invoices_count, billing_country from invoice
group by billing_country
order by invoices_count desc;

# 3. What are the top 3 values of total invoice?
select total from invoice
order by total desc limit 3;

# 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals
select billing_city, sum(total) as invoice_total from invoice
group by billing_city
order by invoice_total desc;

# 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money
select * from customer;
select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total from customer
join invoice on
customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total desc limit 1;

# 6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A
select concat(first_name,' ',last_name) as customer, email from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track on track.track_id = invoice_line.track_id
join genre on track.genre_id = genre.genre_id
where genre.genre_name like 'Rock'
order by email;

# 7. Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands
select artist.artist_id, artist.artist_name, count(artist.artist_id) as no_of_songs from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id  = track.genre_id
where genre.genre_name like 'Rock'
group by artist.artist_id
order by no_of_songs desc limit 10;

# 8. Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first
select track_name, milliseconds from track
where milliseconds > (
	select avg(milliseconds) as avg_track_len from track
)
order by milliseconds desc ;

/* 9.Find how much amount is spent by each customer on artists? Write a query to return customer name, artist name and total spent*/
WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.artist_name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* 10. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres*/
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.genre_name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

/* 11. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount */
WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1


