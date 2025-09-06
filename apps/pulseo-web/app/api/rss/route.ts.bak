import { NextResponse } from "next/server";
export async function GET(req:Request){
  const { searchParams } = new URL(req.url);
  const url = searchParams.get("url");
  if(!url) return NextResponse.json([], { status: 200 });
  const res = await fetch(url, { headers:{ "user-agent":"Pulseo/1.0" }});
  const xml = await res.text();
  const items = Array.from(xml.matchAll(/<item>\s*<title>(.*?)<\/title>.*?<link>(.*?)<\/link>/gs))
    .map((m:any)=>({ title:m[1], link:m[2] }));
  return NextResponse.json(items);
}
