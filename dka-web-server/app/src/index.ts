// @ts-ignore
import express, { Request, Response } from "express";

const app = express()
const port = 3000

app.get('/', (req : Request, res : Response) => {
    res.send('Hello World 2!')
});

app.listen(port, "0.0.0.0", () => {
    console.log(`Example app listening on port ${port}`)
})