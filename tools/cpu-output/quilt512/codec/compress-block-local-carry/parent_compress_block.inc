static void compress_block(deflate_state *s, const ct_data *ltree, const ct_data *dtree) {
    /* ltree: literal tree */
    /* dtree: distance tree */
    unsigned dist;      /* distance of matched string */
    int lc;             /* match length or unmatched char (if dist == 0) */
    unsigned sx = 0;    /* running index in symbol buffers */

    /* Local pointers to avoid indirection */
    const unsigned int sym_next = s->sym_next;
#ifdef LIT_MEM
    uint16_t *d_buf = s->d_buf;
    unsigned char *l_buf = s->l_buf;
#else
    unsigned char *sym_buf = s->sym_buf;
#endif

    if (sym_next != 0) {
        do {
#ifdef LIT_MEM
            dist = d_buf[sx];
            lc = l_buf[sx++];
#else
            dist = sym_buf[sx++] & 0xff;
            dist += (unsigned)(sym_buf[sx++] & 0xff) << 8;
            lc = sym_buf[sx++];
#endif
            if (dist == 0) {
                zng_emit_lit(s, ltree, lc);
            } else {
                zng_emit_dist(s, ltree, dtree, lc, dist);
            } /* literal or match pair ? */

            /* Check for no overlay of pending_buf on needed symbols */
#ifdef LIT_MEM
            Assert(s->pending < 2 * (s->lit_bufsize + sx), "pending_buf overflow");
#else
            Assert(s->pending < s->lit_bufsize + sx, "pending_buf overflow");
#endif
        } while (sx < sym_next);
    }

    zng_emit_end_block(s, ltree, 0);
}
