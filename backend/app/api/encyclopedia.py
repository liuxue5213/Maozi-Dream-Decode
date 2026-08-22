from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.models.encyclopedia import EncyclopediaItem
from app.schemas.encyclopedia import EncyclopediaItemResponse, EncyclopediaSearchResponse, EncyclopediaCategoryResponse

router = APIRouter()


@router.get("/search", response_model=EncyclopediaSearchResponse)
def search(
    keyword: str = Query(..., min_length=1, max_length=50),
    category: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
):
    query = db.query(EncyclopediaItem).filter(
        EncyclopediaItem.status == 1,
        EncyclopediaItem.title.contains(keyword),
    )
    if category:
        query = query.filter(EncyclopediaItem.category == category)
    
    total = query.count()
    offset = (page - 1) * page_size
    items = query.offset(offset).limit(page_size).all()
    
    return EncyclopediaSearchResponse(
        total=total,
        items=[EncyclopediaItemResponse.model_validate(i) for i in items],
    )


@router.get("/categories", response_model=list[EncyclopediaCategoryResponse])
def list_categories(db: Session = Depends(get_db)):
    results = (
        db.query(
            EncyclopediaItem.category,
            func.count(EncyclopediaItem.id).label("count"),
        )
        .filter(EncyclopediaItem.status == 1)
        .group_by(EncyclopediaItem.category)
        .all()
    )
    return [EncyclopediaCategoryResponse(category=r.category, count=r.count) for r in results]


@router.get("/{item_id}", response_model=EncyclopediaItemResponse)
def get_item(item_id: int, db: Session = Depends(get_db)):
    item = db.query(EncyclopediaItem).filter(EncyclopediaItem.id == item_id).first()
    if not item or item.status != 1:
        raise HTTPException(status_code=404, detail="词条不存在")
    return EncyclopediaItemResponse.model_validate(item)


@router.get("", response_model=list[EncyclopediaItemResponse])
def list_items(
    category: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    query = db.query(EncyclopediaItem).filter(EncyclopediaItem.status == 1)
    if category:
        query = query.filter(EncyclopediaItem.category == category)
    
    offset = (page - 1) * page_size
    items = query.order_by(EncyclopediaItem.id).offset(offset).limit(page_size).all()
    return [EncyclopediaItemResponse.model_validate(i) for i in items]
