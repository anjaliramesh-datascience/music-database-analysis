-- Who is the senior most employee?

select * from employee
order by levels desc
limit 1;

-- Which countries have the most invoices?

select billing_country, count(*) as total_invoices from invoice
group by billing_country
order by total_invoices desc;

-- What are the top 3 values of total invoice?

select total from invoice
order by total desc
limit 3;

-- Which city has the best customers? 

select billing_city, sum(total) as total from invoice
group by billing_city
order by total desc;

-- Who is the best customer?

select c.customer_id, c.first_name || ' ' || c.last_name as customer_name, sum(i.total) as total_spent
from customer c 
join invoice i on c.customer_id = i.customer_id
group by c.customer_id
order by total_spent desc
limit 1;

-- Write a query to return the email, first name, last name, genre of all rock music listeners. Return list order alphabetically by email starting with A

select distinct email, first_name, last_name 
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in (
		select track_id from track
		join genre on track.genre_id = genre.genre_id
		where genre.name LIKE 'Rock')
order by email;

-- Identify the artist who have written the most rock music in dataset. Return artist name and total track count on top 10 rock bands

SELECT artist.artist_id, artist.name, count(artist.artist_id) as number_of_songs 
from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
where track.genre_id LIKE '1'
group by artist.artist_id
order by number_of_songs desc
limit 10;

-- Return all track names that have a song length longer than the average song length. Return the name and milliseconds for each track. Order by song length desc

with avg_time as (
				select avg(milliseconds) as avg_time
				from track
)
select name, milliseconds
from track
cross join avg_time
where milliseconds > avg_time
order by milliseconds desc;

-- Find how much amount spent by each customer on best selling artist 
-- Return customer name, artist name and total spent by customer

with best_selling_artist as (
	select artist.artist_id as artist_id, artist.name as artist_name,
	sum(invoice_line.quantity * invoice_line.unit_price) as total_sales
	from invoice_line
	join track on track.track_id = invoice_line.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.artist_id
	group by 1
	order by 3 desc
	limit 1
)
select c.customer_id, c.first_name || ' ' || c.last_name as customer_name, bsa.artist_name,
sum(il.unit_price * il.quantity) as amount_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album a on a.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = a.artist_id
group by 1,2,3
order by 4 desc;

-- Find out the most popular music genre for each country
-- Return country, top genre, number of purchases

with popular_genre as 
(
	select count(invoice_line.quantity) as total_purchases, customer.country, genre.name as genre_name,
	row_number() over(partition by customer.country order by count(invoice_line.quantity) desc) as rowno
	from invoice_line
	join invoice on invoice.invoice_id = invoice_line.invoice_id
	join customer on customer.customer_id = invoice.customer_id
	join track on track.track_id = invoice_line.track_id
	join genre on genre.genre_id = track.genre_id
	group by 2,3
	order by 2 asc, 1 desc	
)

select total_purchases, country, genre_name from popular_genre where rowno <= 1

-- Determine the customer that has spent the most on music for each country
-- Return country, top customer, how much they spent

with recursive
	customer_with_country as (
		select c.customer_id, c.first_name || ' ' || c.last_name as customer_name, i.billing_country,
		sum(i.total) as total_spending
		from invoice i
		join customer c on c.customer_id = i.customer_id
		group by 1,2,3
		order by 4 desc
	),
	
	country_max_spending as (
		select billing_country, max(total_spending) as max_spending
		from customer_with_country
		group by billing_country
	)
	
select cc.billing_country, cc.total_spending, cc.customer_name, cc.customer_id
from customer_with_country cc
join country_max_spending ms
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
order by 1;