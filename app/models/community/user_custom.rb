# class to demonstrate aggregate queries being mapped back into a User object (with extra attributes)
# postgres log function is base 10 by default. log(2, N) is base 2
module Community
class UserCustom

  # the +1 was not there, and I was getting div by 0 errors
  DENOM_SQL = <<-SQL
  ( (max(score) over ()) - (min(score) over ())+1 )

  SQL

  def self.votes_received hours_ago = 24
    start_time = hours_ago.hours.ago
    ActsAsVotable::Vote.select("users.id,users.email,users.username,COUNT(votes.votable_id) as votes_received")
    .joins("LEFT JOIN room_messages ON room_messages.id = votes.votable_id")
    .joins("LEFT JOIN users ON users.id = room_messages.user_id")
    .group("users.id,users.email,users.username")
    .where("votes.votable_type = 'RoomMessage' AND NOT votes.voter_id = users.id AND votes.created_at > ?",start_time)
    .order("votes_received DESC")
  end

  def self.top_conversers_sql

       "(select
       users.id,
       users.is_guest,
       users.username,
       users.id as user_id,
       conversation_count,
       rated_conversation_count,
       vote_count,
       interesting_up,
       interesting_down,
       interesting_count,
       quality_up,
       quality_down,
       quality_count,
       spam_up,
       spam_down,
       spam_count,
       quality_ratio,
       interesting_ratio,
       spam_ratio,
       rated_conversation_count*1.0/MAX(rated_conversation_count) as conv_weight_old,
       round(log(2, (1022 * ((rated_conversation_count - min(rated_conversation_count) over ())::decimal / ( (max(rated_conversation_count) over ()) - (min(rated_conversation_count) over ()) + 1 )) + 2)::numeric), 2) as conv_weight
       from users
       join (
       select user_conversations.user_id as id,
       COUNT(user_conversations) as conversation_count
       from users
       left join user_conversations ON user_conversations.user_id = users.id
       group by user_conversations.user_id
       ) convs using(id)
       join (
       select user_conversations.user_id as id,
       SUM(cached_votes_total) as vote_count,
       SUM(cached_scoped_interesting_votes_up) as interesting_up,
       SUM(cached_scoped_interesting_votes_down) as interesting_down,
       SUM(cached_scoped_interesting_votes_total) as interesting_count,
       SUM(cached_scoped_quality_votes_up) as quality_up,
       SUM(cached_scoped_quality_votes_down) as quality_down,
       SUM(cached_scoped_quality_votes_total) as quality_count,
       SUM(cached_scoped_spam_votes_up) as spam_up,
       SUM(cached_scoped_spam_votes_down) as spam_down,
       SUM(cached_scoped_spam_votes_total) as spam_count,
       COUNT(user_conversations) as rated_conversation_count,
       case 
       when 
        SUM(cached_scoped_interesting_votes_total) = 0 then null 
       else
        (SUM(cached_scoped_interesting_votes_up)*1.0 / SUM(cached_scoped_interesting_votes_total)) 
       end as interesting_ratio,
        case 
       when 
        SUM(cached_scoped_quality_votes_total) = 0 then null 
       else
        (SUM(cached_scoped_quality_votes_up)*1.0 / SUM(cached_scoped_quality_votes_total)) 
       end as quality_ratio,
       case 
       when 
        SUM(cached_scoped_spam_votes_total) = 0 then null 
       else
        (SUM(cached_scoped_spam_votes_up)*1.0 / SUM(cached_scoped_spam_votes_total)) 
       end as spam_ratio
       from users
       left join user_conversations ON user_conversations.user_id = users.id
       left join vote_caches ON vote_caches.resource_id = user_conversations.id
       where vote_caches.resource_type = 'UserConversation'
       group by user_conversations.user_id
       ) rated_convs using(id)
       GROUP BY users.id,
       users.is_guest,
       users.username,
       conversation_count,
       rated_conversation_count,
       vote_count,
       interesting_up,
       interesting_down,
       interesting_count,
       quality_up,
       quality_down,
       quality_count,
       spam_up,
       spam_down,
       spam_count,
       quality_ratio,
       interesting_ratio,
       spam_ratio
       ) as users"
       # ORDER BY interesting_ratio*quality_ratio*(rated_conversation_count*1.0/MAX(rated_conversation_count)) DESC NULLS last
  end

  def self.outdated_sql minutes_ago = 30
    "(select
       users.id,
       users.id as user_id,
       last_updated,
       last_voted
       from users
       join (
       select user_id as id,
       MAX(updated_at) as last_updated
       from item_interests
       group by user_id
       ) interests using(id)
       join (
       select voter_id as id,
       MAX(updated_at) as last_voted
       from votes
       where voter_type = 'User'
       group by voter_id
        
       ) votes using(id)
       ) as users
       where last_updated < '#{minutes_ago.minutes.ago}' AND last_voted > last_updated"

  end


  def self.vote_count_sql hours_ago = 24, show_mins_and_max = false

    start_time = hours_ago.hours.ago
    extra_wh = "AND created_at > '#{start_time}'"
    mins_and_max = "max(vote_count) over () as max_vote_count,
       min(vote_count) over () as min_vote_count," if show_mins_and_max
    "

   (select
       users.id,
       users.email,
       users.username,
       message_count,
       vote_count,
       page_views,
       mins_spent,
       #{mins_and_max}
       round(log(2, (1022 * ((vote_count - min(vote_count) over ())::decimal / ( (max(vote_count) over ()) - (min(vote_count) over ()) + 1 )) + 2)::numeric), 2) as vote_amt,
       round(log(2, (1022 * ((vote_count - min(vote_count) over ())::decimal / ( (max(vote_count) over ()) - (min(vote_count) over ()) + 1 )) + 2)::numeric), 0) as vote_amt_rounded,
       users.sash_id
       from users
      left outer join (
        select user_id as id, 
        COUNT(room_messages.id) as message_count
        from room_messages
        where user_id>0 #{extra_wh}
        group by user_id
      ) messages_info using(id)
      left outer join (
        select voter_id as id, 
        COUNT(votes.id) as vote_count
        from votes
        where voter_type = 'User' #{extra_wh}
        group by voter_id
      ) votes_info using(id)
      left outer join (
        select user_id as id, 
        COUNT(impressions.id) as page_views,
        SUM(impressions.seconds)/60 as mins_spent
        from impressions
        where true #{extra_wh}
        group by user_id
      ) views_info using(id)
    ) as users
    where vote_count > 0
    "

  end

 # excludes upvotes on their own posts
  RANKED_DEV_SQL2 = <<-SQL
      (select
       users.id,
       users.first_name,
       users.last_name,
       post_count,
       (post_count / (post_upvotes_rec::decimal/post_upvotes_made)) as post_count_adj,
       (post_upvotes_rec::decimal/post_upvotes_made) as upvote_ratio,
       (max(post_upvotes_rec::decimal/post_upvotes_made) over() ) as max_upvote_ratio,
       (min(post_upvotes_rec::decimal/post_upvotes_made) over() ) as min_upvote_ratio,

       

       post_upvotes_made,
       post_upvotes_rec,
       my_posts_upvoted as post_upvotes_rec_unaudited,
       toggles_rec,
       toggles,

       (max(my_posts_upvoted - post_upvotes_made) over() ) as max_inbound,
       (min(my_posts_upvoted - post_upvotes_made) over() ) as min_inbound,
       (max(post_upvotes_made - my_posts_upvoted) over() ) as max_outbound,
       (min(post_upvotes_made - my_posts_upvoted) over() ) as min_outbound,
       max(post_count) over () as max_post_count,
       min(post_count) over () as min_post_count,
       (post_count - min(post_count) over ()) as numerator,
       ( (max(post_count) over ()) - (min(post_count) over ()) ) as denominator,
       (  (post_count - min(post_count) over ())::decimal / ( (max(post_count) over ()) - (min(post_count) over ()) )  ) as divided,
       round(toggles::numeric / post_upvotes_made, 2) as toggles_per_upvote_made,

       round(log(2, (1022 * ((post_count - min(post_count) over ())::decimal / ( (max(post_count) over ()) - (min(post_count) over ()) )) + 2)::numeric), 2) as post_amt,
  
       users.name,
       users.avatar_url
      from users
      join (
        select created_by as id, 
        COUNT(posts.id) as post_count,
        sum(upvote_counter) as my_posts_upvoted
        from posts
        group by created_by
      ) posts_info using(id)
      join (
        select
        p3.created_by as id,
        p3.created_by,
        count(*) as post_upvotes_rec,
        sum(pu2.toggles) as toggles_rec
        from posts p3
        left join post_upvotes pu2 ON p3.id = pu2.post_id
        where NOT pu2.removed = true AND NOT pu2.created_by = p3.created_by
        group by p3.created_by
      ) posts_upvoted using(id)
      join (
        select
        post_upvotes.created_by,
        post_upvotes.created_by as id,
        count(*) as post_upvotes_made,
        sum(toggles) as toggles
        from post_upvotes
        left join posts p2 ON p2.id = post_upvotes.post_id
        where NOT post_upvotes.removed = true AND NOT post_upvotes.created_by = p2.created_by
        group by post_upvotes.created_by
      ) post_upvotes using(id)
      ) as users
      where post_count > 0 AND post_upvotes_made > 0 AND post_upvotes_rec > 0
    SQL

# excludes upvotes on their own posts
  RANKED_DEV_SQL = <<-SQL
      (select
       users.id,
       users.first_name,
       users.last_name,
       post_count,
       (post_count / (post_upvotes_rec::decimal/post_upvotes_made)) as post_count_adj,
       (post_upvotes_rec::decimal/post_upvotes_made) as upvote_ratio,
       (max(post_upvotes_rec::decimal/post_upvotes_made) over() ) as max_upvote_ratio,
       (min(post_upvotes_rec::decimal/post_upvotes_made) over() ) as min_upvote_ratio,



       post_upvotes_made,
       post_upvotes_rec,
       my_posts_upvoted as post_upvotes_rec_unaudited,
       toggles_rec,
       toggles,

       (max(my_posts_upvoted - post_upvotes_made) over() ) as max_inbound,
       (min(my_posts_upvoted - post_upvotes_made) over() ) as min_inbound,
       (max(post_upvotes_made - my_posts_upvoted) over() ) as max_outbound,
       (min(post_upvotes_made - my_posts_upvoted) over() ) as min_outbound,
       max(post_count) over () as max_post_count,
       min(post_count) over () as min_post_count,
       (post_count - min(post_count) over ()) as numerator,
       ( (max(post_count) over ()) - (min(post_count) over ()) ) as denominator,
       (  (post_count - min(post_count) over ())::decimal / ( (max(post_count) over ()) - (min(post_count) over ()) )  ) as divided,
       round(toggles::numeric / post_upvotes_made, 2) as toggles_per_upvote_made,

       round(log(2, (1022 * ((post_count - min(post_count) over ())::decimal / ( (max(post_count) over ()) - (min(post_count) over ()) )) + 2)::numeric), 2) as post_amt,
  
       users.name,
       users.avatar_url
      from users
      join (
        select created_by as id, 
        COUNT(posts.id) as post_count,
        sum(upvote_counter) as my_posts_upvoted
        from posts
        group by created_by
      ) posts_info using(id)
      join (
        select
        p3.created_by as id,
        p3.created_by,
        count(*) as post_upvotes_rec,
        sum(pu2.toggles) as toggles_rec
        from posts p3
        left join post_upvotes pu2 ON p3.id = pu2.post_id
        where NOT pu2.removed = true AND NOT pu2.created_by = p3.created_by
        group by p3.created_by
      ) posts_upvoted using(id)
      join (
        select
        post_upvotes.created_by,
        post_upvotes.created_by as id,
        count(*) as post_upvotes_made,
        sum(toggles) as toggles
        from post_upvotes
        left join posts p2 ON p2.id = post_upvotes.post_id
        where NOT post_upvotes.removed = true AND NOT post_upvotes.created_by = p2.created_by
        group by post_upvotes.created_by
      ) post_upvotes using(id)
      ) as users
      where post_count > 0 AND post_upvotes_made > 0 AND post_upvotes_rec > 0
    SQL

# AND ((post_upvotes_rec-post_upvotes_made) > 0)
# AND ((my_posts_upvoted-post_upvotes_made) > 0) MORE received than given
# AND ((my_posts_upvoted-post_upvotes_made) < 0) FEWER upvotes received than given



  def self.voters(count=1,hours_ago = 24, version=1)
    sql = UserCustom.vote_count_sql(hours_ago) #version == 1 ? RANKED_DEV_SQL : UserCustom.build_alg #RANKED_DEV_SQL2
    User.from(sql)
      .order(vote_count: :desc)
      .limit(count)
  end

  def self.top_conversers
    User.from(UserCustom.top_conversers_sql)
    .order("interesting_ratio*quality_ratio*conv_weight DESC NULLS last")
    #.order("interesting_ratio DESC NULLS last")
  end

  def self.top_users(count=1,version=1)
    sql = version == 1 ? RANKED_DEV_SQL : UserCustom.build_alg #RANKED_DEV_SQL2
    User.from(sql)
      .order(post_amt: :desc)
      .limit(count)
  end

  def self.bottom_users(count=1,version=1)
    sql = version == 1 ? RANKED_DEV_SQL : UserCustom.build_alg #RANKED_DEV_SQL2
    User.from(sql)
      .order(post_amt: :asc)
      .limit(count)
  end

  def self.top_supporters(count=1,version=1)
    sql = UserCustom.build_alg
    User.from(sql)
    .order(upvote_ratio_normalized: :asc)
    .limit(count)
  end

  def self.top_supported(count=1,version=1)
    sql = UserCustom.build_alg
    User.from(sql)
    .order(upvote_ratio_normalized: :desc)
    .limit(count)
  end

  def self.outdated_interests minutes_ago: 30, count: 2000 
    sql = UserCustom.outdated_sql
    User.from(sql)
    .limit(count)

  end


  def self.build_alg

    upvote_ratio = " (post_upvotes_rec::decimal/post_upvotes_made) "
    max_upvote_ratio = " (max(post_upvotes_rec::decimal/post_upvotes_made) over() ) "
    min_upvote_ratio = " (min(post_upvotes_rec::decimal/post_upvotes_made) over() ) "

    "
      (select
       users.id,
       users.first_name,
       users.last_name,
       post_count,
       (post_count / (post_upvotes_rec::decimal/post_upvotes_made)) as post_count_adj,
       #{upvote_ratio} as upvote_ratio,
       round(log(2, (1022 * ((#{upvote_ratio} - #{min_upvote_ratio})::decimal / ( #{max_upvote_ratio} - (#{min_upvote_ratio}) )) + 2)::numeric), 2) as upvote_ratio_normalized,
       #{max_upvote_ratio} as max_upvote_ratio,
       #{min_upvote_ratio} as min_upvote_ratio,

       post_upvotes_made,
       post_upvotes_rec,
       my_posts_upvoted as post_upvotes_rec_unaudited,
       toggles_rec,
       toggles,

       (max(my_posts_upvoted - post_upvotes_made) over() ) as max_inbound,
       (min(my_posts_upvoted - post_upvotes_made) over() ) as min_inbound,
       (max(post_upvotes_made - my_posts_upvoted) over() ) as max_outbound,
       (min(post_upvotes_made - my_posts_upvoted) over() ) as min_outbound,
       max(post_count) over () as max_post_count,
       min(post_count) over () as min_post_count,
       (post_count - min(post_count) over ()) as numerator,
       ( (max(post_count) over ()) - (min(post_count) over ()) ) as denominator,
       (  (post_count - min(post_count) over ())::decimal / ( (max(post_count) over ()) - (min(post_count) over ()) )  ) as divided,
       round(toggles::numeric / post_upvotes_made, 2) as toggles_per_upvote_made,

       round(log(2, (1022 * ((post_count - min(post_count) over ())::decimal / ( (max(post_count) over ()) - (min(post_count) over ()) )) + 2)::numeric), 2) as post_amt,
  
       users.name,
       users.avatar_url
      from users
      join (
        select created_by as id, 
        COUNT(posts.id) as post_count,
        sum(upvote_counter) as my_posts_upvoted
        from posts
        group by created_by
      ) posts_info using(id)
      join (
        select
        p3.created_by as id,
        p3.created_by,
        count(*) as post_upvotes_rec,
        sum(pu2.toggles) as toggles_rec
        from posts p3
        left join post_upvotes pu2 ON p3.id = pu2.post_id
        where NOT pu2.removed = true AND NOT pu2.created_by = p3.created_by
        group by p3.created_by
      ) posts_upvoted using(id)
      join (
        select
        post_upvotes.created_by,
        post_upvotes.created_by as id,
        count(*) as post_upvotes_made,
        sum(toggles) as toggles
        from post_upvotes
        left join posts p2 ON p2.id = post_upvotes.post_id
        where NOT post_upvotes.removed = true AND NOT post_upvotes.created_by = p2.created_by
        group by post_upvotes.created_by
      ) post_upvotes using(id)
      ) as users
      where post_count > 0 AND post_upvotes_made > 0 AND post_upvotes_rec > 0
    "


  end
end
end
=begin
# keep getting div by 0 errors
class UserCustom
  RANKED_DEV_SQL = <<-SQL
      (select
       users.id,
       users.name,
       users.first_name,
       users.last_name,
       users.avatar_url,
       upvotes,
       toggles,
       round(toggles::numeric / upvotes, 2) as avg_upvotes,
       round(log(2, (1022 * ((score - min(score) over ()) / ((max(score) over ()) - (min(score) over ()))) + 2)::numeric), 1) as hotness
      from users
      join (
        select created_by as id, sum(upvote_counter) as score
        from posts
        where created_by='2'
        group by created_by
      ) item_scores using(id)
      join (
        select
        created_by as id,
        count(*) as upvotes,
        sum(toggles) as toggles
        from post_upvotes
        where created_by='2'
        group by created_by
      ) stats using(id)
      ) as users
      where users.id = '2'
    SQL

  def self.top_users(count=1)
    User.from(RANKED_DEV_SQL)
      .order(hotness: :desc)
      .limit(count)
  end

  def self.bottom_users(count=1)
    User.from(RANKED_DEV_SQL)
      .order(hotness: :asc)
      .limit(count)
  end
end
=end
=begin
class DeveloperRanker
  RANKED_DEV_SQL = <<-SQL
      (select
       developers.id,
       username,
       posts,
       likes,
       round(likes::numeric / posts, 2) as avg_likes,
       round(log(2, (1022 * ((score - min(score) over ()) / ((max(score) over ()) - (min(score) over ()))) + 2)::numeric), 1) as hotness
      from developers
      join (
        select developer_id as id, sum(score) as score
        from hot_posts
        group by developer_id
      ) developer_scores using(id)
      join (
        select
        developer_id as id,
        count(*) as posts,
        sum(likes) as likes
        from posts
        group by developer_id
      ) stats using(id)
      ) as developers
    SQL

  def self.top_developers(count=1)
    Developer.from(RANKED_DEV_SQL)
      .order(hotness: :desc)
      .limit(count)
  end

  def self.bottom_developers(count=1)
    Developer.from(RANKED_DEV_SQL)
      .order(hotness: :asc)
      .limit(count)
  end
end
=end