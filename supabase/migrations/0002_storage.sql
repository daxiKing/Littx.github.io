insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('littx-releases','littx-releases',false,104857600,array['application/java-archive','application/octet-stream']) on conflict(id) do update set public=false;
-- Private bucket: no direct object policies. Server creates short-lived signed URLs only after entitlement checks.
