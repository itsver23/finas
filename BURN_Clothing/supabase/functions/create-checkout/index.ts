import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{'Content-Type':'application/json'}});
serve(async(req)=>{
  if(req.method!=='POST')return json({error:'Method not allowed'},405);
  try{
    const jwt=req.headers.get('Authorization')?.replace(/^Bearer /,'');
    if(!jwt)return json({error:'Unauthorized'},401);
    const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const {data:{user},error:authError}=await admin.auth.getUser(jwt);
    if(authError||!user)return json({error:'Unauthorized'},401);
    const {items,address_id,delivery}=await req.json();
    if(!Array.isArray(items)||items.length===0||items.length>30||!['Standard','Express'].includes(delivery))return json({error:'Invalid checkout'},400);
    const {data:address}=await admin.from('addresses').select('id').eq('id',address_id).eq('user_id',user.id).maybeSingle();
    if(!address)return json({error:'Invalid address'},400);
    const quantities=new Map<string,number>();
    for(const item of items){if(typeof item.product_id!=='string'||!Number.isInteger(item.quantity)||item.quantity<1||item.quantity>20)return json({error:'Invalid item'},400);quantities.set(item.product_id,(quantities.get(item.product_id)||0)+item.quantity);}
    const {data:products,error:pError}=await admin.from('products').select('id,price,stock,active').in('id',[...quantities.keys()]);
    if(pError||!products||products.length!==quantities.size||products.some(p=>!p.active||p.stock<(quantities.get(p.id)||0)))return json({error:'Product unavailable or insufficient stock'},409);
    const subtotal=products.reduce((s,p)=>s+p.price*quantities.get(p.id)!,0);const shipping=delivery==='Express'?150:70;const total=subtotal+shipping;
    const external_id=crypto.randomUUID();
    const {data:order,error:oError}=await admin.from('orders').insert({user_id:user.id,address_id,subtotal,shipping,total,external_id}).select('id').single();
    if(oError)throw oError;
    const {error:iError}=await admin.from('order_items').insert(products.map(p=>({order_id:order.id,product_id:p.id,quantity:quantities.get(p.id),unit_price:p.price})));
    if(iError)throw iError;
    const secret=Deno.env.get('XENDIT_SECRET_KEY');if(!secret)throw new Error('Xendit secret missing');
    const auth=btoa(secret+':');
    const result=await fetch('https://api.xendit.co/v2/invoices',{method:'POST',headers:{Authorization:`Basic ${auth}`,'Content-Type':'application/json'},body:JSON.stringify({external_id,amount:total,currency:'PHP',description:`BURN Clothing order ${order.id}`,customer:{given_names:user.user_metadata?.full_name||'Customer',email:user.email},invoice_duration:86400})});
    const invoice=await result.json();if(!result.ok||!invoice.invoice_url)throw new Error('Payment gateway request failed');
    await admin.from('orders').update({invoice_id:invoice.id,invoice_url:invoice.invoice_url}).eq('id',order.id);
    return json({order_id:order.id,invoice_url:invoice.invoice_url});
  }catch(e){console.error('checkout failed',e);return json({error:'Checkout could not be created'},500);}
});
