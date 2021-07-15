<% room = nil if local_assigns[:room].nil? %>
<div class="border bg-white p-1 m-1 rounded" org-id="<%= org.id %>">
 <div>You were removed from <%= link_to org.name, org %></div>
 <% unless room.nil? %>
 <div>Within <%= link_to room.name, room %></div>
 <% end %>
</div>