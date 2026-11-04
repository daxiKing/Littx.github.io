import type { Metadata } from "next";
import "./globals.css";
import { SiteNav } from "@/components/site-nav";
export const metadata: Metadata = { title: "LITTX CLIENT — Beyond Vanilla", description: "LITTX CLIENT for Minecraft 1.8.9. Explore editions, releases and updates.", themeColor: "#08090d" };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="en"><body><div className="noise"/><SiteNav/><main>{children}</main><footer className="footer"><span><b>LITTX CLIENT</b> © 2026</span><span>Minecraft 1.8.9 · Unofficial community project</span><a href="#top">Back to top ↑</a></footer></body></html>; }
