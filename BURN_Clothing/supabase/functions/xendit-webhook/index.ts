import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
serve(async(req)=>{
  if(req.method!=='POST')return new Response('Method not allowed',{status:405});
  const token=Deno.env.get('XENDIT_CALLBACK_TOKEN');
  if(!token||req.headers.get('x-callback-token')!==token)return new Response('Unauthorized',{status:401});
  try{
    const event=await req.json();
    if(!['PAID','EXPIRED','FAILED'].includes(event.status)||typeof event.external_id!=='string')return new Response('Ignored',{status:200});
    const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const {data:order}=await admin.from('orders').select('id,total,status,invoice_id').eq('external_id',event.external_id).maybeSingle();
    if(!order)return new Response('Not found',{status:404});
    if(order.status==='PAID')return new Response('OK',{status:200});
    if(event.status==='PAID'&&(Number(event.paid_amount??event.amount)!==order.total||event.id!==order.invoice_id))return new Response('Invoice mismatch',{status:400});
    const {error}=await admin.from('orders').update({status:event.status}).eq('id',order.id).eq('status','PENDING');
    if(error)throw error;
    return new Response('OK',{status:200});
  }catch(e){console.error(e);return new Response('Webhook error',{status:500});}
});
