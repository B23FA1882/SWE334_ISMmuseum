import React, { useEffect, useRef, useState } from 'react';
/** Adapted from the user-supplied 21st.dev CircularGallery for React + JavaScript. */
export function CircularGallery({items = [], radius = 420, autoRotateSpeed = .09, className = ''}) {
  const [rotation, setRotation] = useState(0);
  const [paused, setPaused] = useState(false);
  const touch = useRef(null);
  const rot = useRef(0);
  const update = value => {rot.current = value; setRotation(value);};
  useEffect(()=>{if(paused||items.length<2||window.matchMedia('(prefers-reduced-motion: reduce)').matches)return;
    let id, prev;const tick=t=>{if(prev!==undefined)update(rot.current+Math.min(t-prev,80)*autoRotateSpeed*.06);prev=t;id=requestAnimationFrame(tick);};
    id=requestAnimationFrame(tick);return()=>cancelAnimationFrame(id);
  },[paused,autoRotateSpeed,items.length]);
  if(!items.length) return <p>Одоогоор үзүүлэх зураг алга.</p>;
  return <div className={'gallery-stage '+className} role="region" aria-label="3 хэмжээст интерактив зургийн цомог" onMouseEnter={()=>setPaused(true)} onMouseLeave={()=>setPaused(false)} onTouchStart={e=>{touch.current=e.touches[0].clientX;setPaused(true);}} onTouchMove={e=>{if(touch.current!==null){const now=e.touches[0].clientX;update(rot.current+(now-touch.current)*.35);touch.current=now;}}} onTouchEnd={()=>{touch.current=null;setPaused(false);}}>
  <div className="gallery-ring" style={{transform:`rotateY(${rotation}deg)`}}>
    {items.map((item,i)=>{
      const theta=360*i/items.length, diff=Math.abs(((theta+rotation)%360+540)%360-180);
      return <div className="gallery-panel" key={item.id||i} style={{transform:`translate(-50%,-50%) rotateY(${theta}deg) translateZ(${radius}px)`,opacity: Math.max(.24,1-diff/240)}}>
        <img src={item.image} alt={item.title} loading="lazy"/><div className="gallery-panel-caption"><small>{item.subtitle||'ISM ARCHIVE'}</small><strong>{item.title}</strong></div>
      </div>;
    })}
  </div>
  <div className="gallery-controls"><button type="button" aria-label="Өмнөх зураг" onClick={()=>update(rot.current+360/items.length)}>←</button><span>DRAG / EXPLORE</span><button type="button" aria-label="Дараагийн зураг" onClick={()=>update(rot.current-360/items.length)}>→</button></div>
  </div>;
}
