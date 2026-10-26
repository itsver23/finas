class Item {
  final String id, name, category, image;
  final int price, stock;
  const Item(this.id, this.name, this.category, this.price, this.image, [this.stock=100]);
  factory Item.fromJson(Map<String,dynamic> m) => Item(m['id'].toString(),m['name'].toString(),m['category'].toString(), (m['price'] as num).round(),(m['image_url']??'').toString(),(m['stock'] as num?)?.toInt()??0);
}
const demoItems = [
  Item('demo-tee','BURN Essential Tee','Men',399,''),
  Item('demo-hoodie','BURN Oversized Hoodie','Unisex',999,''),
  Item('demo-cargo','BURN Cargo Pants','Men',799,''),
  Item('demo-cap','BURN Street Cap','Accessories',299,''),
  Item('demo-top','BURN Street Top','Ladies',449,''),
  Item('demo-shoes','BURN Urban Sneakers','Footwear',1299,''),
];
